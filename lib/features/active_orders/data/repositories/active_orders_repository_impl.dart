import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/active_orders/domain/models/active_order_item.dart';
import 'package:customer_app/features/active_orders/domain/repositories/i_active_orders_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_orders_repository_impl.g.dart';

// keepAlive so the in-flight guard + TTL cache below survive across the many
// `ref.read`s that hit this repo (auth init, the active-orders banner, the
// router's pop observer, the home tab tap). Without it the provider — and its
// dedup state — would be recreated per read, defeating the coalescing.
@Riverpod(keepAlive: true)
IActiveOrdersRepository activeOrdersRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ActiveOrdersRepositoryImpl(apiService);
}

class ActiveOrdersRepositoryImpl implements IActiveOrdersRepository {
  final ApiService _apiService;

  ActiveOrdersRepositoryImpl(this._apiService);

  /// Serve a cached result for this long before hitting the network again.
  /// Long enough to absorb the startup burst (auth init + banner mount fire
  /// near-simultaneously) and rapid back-navigation; short enough that active
  /// order status stays fresh.
  static const _cacheTtl = Duration(seconds: 5);

  List<ActiveOrderItem>? _cache;
  DateTime? _cachedAt;
  Future<List<ActiveOrderItem>>? _inFlight;

  @override
  Future<List<ActiveOrderItem>> getActiveOrders({bool forceRefresh = false}) {
    // 1. Fresh-enough cache → no round-trip.
    final cachedAt = _cachedAt;
    final cache = _cache;
    if (!forceRefresh &&
        cache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return Future.value(cache);
    }

    // 2. A request is already running → ride along instead of firing another.
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    // 3. Start one request; everyone above shares this future.
    final future = _fetch();
    _inFlight = future;
    return future;
  }

  Future<List<ActiveOrderItem>> _fetch() async {
    try {
      final response = await _apiService.dio.get('/api/customer/active');
      // Shape: { "active": ActiveItem[], "total": number } — 200 even when
      // idle (empty list), unlike /jobs/active which 404s.
      final data = response.data;
      final active = data is Map<String, dynamic> ? data['active'] : null;
      final result = active is! List
          ? const <ActiveOrderItem>[]
          : active
                .whereType<Map<String, dynamic>>()
                .map(ActiveOrderItem.fromJson)
                .toList();
      _cache = result;
      _cachedAt = DateTime.now();
      return result;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      throw Exception(message ?? 'Failed to fetch active orders');
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      _inFlight = null;
    }
  }
}
