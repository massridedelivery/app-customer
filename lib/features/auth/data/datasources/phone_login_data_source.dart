import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'phone_login_data_source.g.dart';

abstract class PhoneLoginDataSource {
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required String role,
  });

  Future<Map<String, dynamic>> sendVerifyOtp({
    required String phone,
    required String otp,
    required String role,
    required String refId,
    String? fullName,
  });
}

@riverpod
PhoneLoginDataSourceImpl phoneLoginDataSource(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PhoneLoginDataSourceImpl(apiService);
}

class PhoneLoginDataSourceImpl implements PhoneLoginDataSource {
  final ApiService _apiService;

  PhoneLoginDataSourceImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required String role,
  }) async {
    final response = await _apiService.dio.post(
      '/auth/otp/send',
      data: {'phone': phone, 'role': role},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> sendVerifyOtp({
    required String phone,
    required String otp,
    required String role,
    required String refId,
    String? fullName,
  }) async {
    final response = await _apiService.dio.post(
      '/auth/otp/verify',
      data: {
        'phone': phone,
        'otp': otp,
        'role': role,
        'ref_id': refId,
        'full_name': ?fullName,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
