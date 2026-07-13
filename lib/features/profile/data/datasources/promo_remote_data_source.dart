import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'promo_remote_data_source.g.dart';

@riverpod
PromoRemoteDataSource promoRemoteDataSource(Ref ref) =>
    PromoRemoteDataSource(ref.watch(apiServiceProvider));

/// Remote endpoints for browsing the promotions catalogue.
class PromoRemoteDataSource {
  PromoRemoteDataSource(this._api);

  final ApiService _api;

  /// GET /api/customer/promo/list
  Future<List<dynamic>> getList() async {
    final res = await _api.dio.get('/api/customer/promo/list');
    return res.data as List<dynamic>;
  }

  /// GET /api/customer/promo/{id}
  Future<Map<String, dynamic>> getDetail(String id) async {
    final res = await _api.dio.get('/api/customer/promo/$id');
    return res.data as Map<String, dynamic>;
  }
}
