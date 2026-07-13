import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sos_remote_data_source.g.dart';

@riverpod
SosRemoteDataSource sosRemoteDataSource(Ref ref) =>
    SosRemoteDataSource(ref.watch(apiServiceProvider));

/// Remote endpoints for the emergency SOS feature.
class SosRemoteDataSource {
  SosRemoteDataSource(this._api);

  final ApiService _api;

  /// GET /api/customer/sos/history
  Future<List<dynamic>> getHistory({int limit = 10}) async {
    final res = await _api.dio.get(
      '/api/customer/sos/history',
      queryParameters: {'limit': limit},
    );
    return res.data as List<dynamic>;
  }

  /// POST /api/customer/sos
  Future<Map<String, dynamic>> trigger(Map<String, dynamic> body) async {
    final res = await _api.dio.post('/api/customer/sos', data: body);
    return res.data as Map<String, dynamic>;
  }
}
