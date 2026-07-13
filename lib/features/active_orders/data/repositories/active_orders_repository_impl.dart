import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/active_orders/domain/models/active_order_item.dart';
import 'package:customer_app/features/active_orders/domain/repositories/i_active_orders_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_orders_repository_impl.g.dart';

@riverpod
IActiveOrdersRepository activeOrdersRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ActiveOrdersRepositoryImpl(apiService);
}

class ActiveOrdersRepositoryImpl implements IActiveOrdersRepository {
  final ApiService _apiService;

  ActiveOrdersRepositoryImpl(this._apiService);

  @override
  Future<List<ActiveOrderItem>> getActiveOrders() async {
    try {
      final response = await _apiService.dio.get('/api/customer/active');
      // Shape: { "active": ActiveItem[], "total": number } — 200 even when
      // idle (empty list), unlike /jobs/active which 404s.
      final data = response.data;
      final active = data is Map<String, dynamic> ? data['active'] : null;
      if (active is! List) return const [];
      return active
          .whereType<Map<String, dynamic>>()
          .map(ActiveOrderItem.fromJson)
          .toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      throw Exception(message ?? 'Failed to fetch active orders');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
