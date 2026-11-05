import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'promo_remote_data_source.g.dart';

@riverpod
PromoRemoteDataSource promoRemoteDataSource(Ref ref) => PromoRemoteDataSource(
      ref.watch(apiServiceProvider),
      ref.watch(tokenStorageProvider),
    );

/// Remote endpoints for browsing the promotions catalogue.
///
/// Guests use the public endpoints (no token, never a 401); logged-in customers
/// use the customer endpoints. Both return the same shape.
class PromoRemoteDataSource {
  PromoRemoteDataSource(this._api, this._tokenStorage);

  final ApiService _api;
  final TokenStorage _tokenStorage;

  bool get _auth => _tokenStorage.hasToken;

  /// GET /api/customer/promo/list (auth) or /api/public/promos (guest)
  Future<List<dynamic>> getList() async {
    final path = _auth ? '/api/customer/promo/list' : '/api/public/promos';
    final res = await _api.dio.get(path);
    return res.data as List<dynamic>;
  }

  /// What a checkout can use for [appliesTo] (RIDE | FOOD | MESSENGER):
  /// signed in, GET /api/customer/promos/context — promotions (kind PROMO)
  /// then the customer's points coupons (kind VOUCHER); a guest has no
  /// coupons, so the public list.
  Future<List<dynamic>> getForService(String appliesTo) async {
    if (!_auth) return getList();
    final res = await _api.dio.get(
      '/api/customer/promos/context',
      queryParameters: {'applies_to': appliesTo},
    );
    final data = res.data;
    if (data is List) return data;
    return (data is Map ? (data['items'] ?? data['promos']) as List? : null) ??
        const [];
  }

  /// GET /api/customer/promo/{id} (auth) or /api/public/promos/{id} (guest)
  Future<Map<String, dynamic>> getDetail(String id) async {
    final path =
        _auth ? '/api/customer/promo/$id' : '/api/public/promos/$id';
    final res = await _api.dio.get(path);
    return res.data as Map<String, dynamic>;
  }
}
