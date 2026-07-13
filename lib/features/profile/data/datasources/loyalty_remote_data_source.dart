import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loyalty_remote_data_source.g.dart';

@riverpod
LoyaltyRemoteDataSource loyaltyRemoteDataSource(Ref ref) =>
    LoyaltyRemoteDataSource(ref.watch(apiServiceProvider));

/// Remote endpoints for the loyalty / rewards feature (points & cashback).
class LoyaltyRemoteDataSource {
  LoyaltyRemoteDataSource(this._api);

  final ApiService _api;

  /// GET /api/customer/loyalty/summary
  Future<Map<String, dynamic>> getSummary() async {
    final res = await _api.dio.get('/api/customer/loyalty/summary');
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/loyalty/points
  Future<Map<String, dynamic>> getPoints({int limit = 20}) async {
    final res = await _api.dio.get(
      '/api/customer/loyalty/points',
      queryParameters: {'limit': limit},
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /api/customer/loyalty/points/redeem
  Future<Map<String, dynamic>> redeemPoints(int points) async {
    final res = await _api.dio.post(
      '/api/customer/loyalty/points/redeem',
      data: {'points': points},
    );
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/loyalty/cashback
  Future<List<dynamic>> getCashbackHistory({int limit = 20}) async {
    final res = await _api.dio.get(
      '/api/customer/loyalty/cashback',
      queryParameters: {'limit': limit},
    );
    return res.data as List<dynamic>;
  }
}
