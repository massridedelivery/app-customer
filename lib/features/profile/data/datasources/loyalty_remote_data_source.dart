import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/core/services/idempotency.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loyalty_remote_data_source.g.dart';

@riverpod
LoyaltyRemoteDataSource loyaltyRemoteDataSource(Ref ref) =>
    LoyaltyRemoteDataSource(ref.watch(apiServiceProvider));

/// Remote endpoints for points, rewards (แลกคะแนน) and vouchers.
class LoyaltyRemoteDataSource {
  LoyaltyRemoteDataSource(this._api);

  final ApiService _api;

  /// GET /api/customer/loyalty/summary
  Future<Map<String, dynamic>> getSummary() async {
    final res = await _api.dio.get('/api/customer/loyalty/summary');
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/loyalty/points — history, newest first, by offset.
  Future<Map<String, dynamic>> getPoints({int limit = 20, int offset = 0}) async {
    final res = await _api.dio.get(
      '/api/customer/loyalty/points',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/rewards — what points can be exchanged for.
  Future<Map<String, dynamic>> getRewards() async {
    final res = await _api.dio.get('/api/customer/rewards');
    return res.data as Map<String, dynamic>;
  }

  /// POST /api/customer/rewards/{id}/redeem. Send the same [idempotencyKey]
  /// on a retry of one tap: the server replays the first voucher instead of
  /// spending points twice.
  Future<Map<String, dynamic>> redeemReward(
    String id, {
    required String idempotencyKey,
  }) async {
    final res = await _api.dio.post(
      '/api/customer/rewards/${Uri.encodeComponent(id)}/redeem',
      options: Options(headers: {kIdempotencyHeader: idempotencyKey}),
    );
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/vouchers?status=ACTIVE|USED|EXPIRED.
  Future<Map<String, dynamic>> getVouchers({String status = 'ACTIVE'}) async {
    final res = await _api.dio.get(
      '/api/customer/vouchers',
      queryParameters: {'status': status},
    );
    return res.data as Map<String, dynamic>;
  }
}
