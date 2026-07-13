import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_remote_data_source.g.dart';

abstract interface class RegisterRemoteDataSource {
  Future<void> register({required String email, required String fullName});
  Future<void> registerDevice({
    required String token,
    required String deviceType,
  });
}

@riverpod
RegisterRemoteDataSource registerRemoteDataSource(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RegisterRemoteDataSourceImpl(apiService);
}

class RegisterRemoteDataSourceImpl implements RegisterRemoteDataSource {
  final ApiService _apiService;

  RegisterRemoteDataSourceImpl(this._apiService);

  @override
  Future<void> register({
    required String email,
    required String fullName,
  }) async {
    await _apiService.dio.post(
      '/auth/register',
      data: {'email': email, 'role': 'customer', 'full_name': fullName},
    );
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String deviceType,
  }) async {
    await _apiService.dio.post(
      '/api/notifications/register-device',
      data: {'token': token, 'device_type': deviceType},
    );
  }
}
