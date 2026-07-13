import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'referral_remote_data_source.g.dart';

@riverpod
ReferralRemoteDataSource referralRemoteDataSource(Ref ref) =>
    ReferralRemoteDataSource(ref.watch(apiServiceProvider));

/// Remote endpoints for the referral programme.
class ReferralRemoteDataSource {
  ReferralRemoteDataSource(this._api);

  final ApiService _api;

  /// GET /api/customer/loyalty/referral
  Future<Map<String, dynamic>> getInfo() async {
    final res = await _api.dio.get('/api/customer/loyalty/referral');
    return res.data as Map<String, dynamic>;
  }

  /// POST /api/customer/loyalty/referral/apply
  Future<Map<String, dynamic>> applyCode(String code) async {
    final res = await _api.dio.post(
      '/api/customer/loyalty/referral/apply',
      data: {'code': code},
    );
    return res.data as Map<String, dynamic>;
  }
}
