import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_remote_data_source.g.dart';

@riverpod
AccountRemoteDataSource accountRemoteDataSource(Ref ref) =>
    AccountRemoteDataSource(ref.watch(apiServiceProvider));

/// Remote endpoints for account management & PDPA (data export, deletion).
class AccountRemoteDataSource {
  AccountRemoteDataSource(this._api);

  final ApiService _api;

  /// DELETE /api/customer/account
  Future<Map<String, dynamic>> requestDeletion(String reason) async {
    final res = await _api.dio.delete(
      '/api/customer/account',
      data: {'reason': reason},
    );
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/export
  Future<Map<String, dynamic>> exportData() async {
    final res = await _api.dio.get('/api/customer/export');
    return res.data as Map<String, dynamic>;
  }
}
