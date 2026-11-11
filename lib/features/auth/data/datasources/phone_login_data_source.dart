import 'package:customer_app/core/data/install_id.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/crash_reporting.dart';
import 'package:customer_app/core/services/retry_interceptor.dart';
import 'package:dio/dio.dart';
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
  return PhoneLoginDataSourceImpl(apiService.dio, ref.watch(installIdProvider));
}

class PhoneLoginDataSourceImpl implements PhoneLoginDataSource {
  final Dio _dio;

  /// Stable per install: the backend rate-limits sends per device.
  final String _deviceId;

  PhoneLoginDataSourceImpl(this._dio, this._deviceId);

  /// Sends the code. Returns the body only for a 200 that carries a `ref_id`;
  /// anything else throws (a [DioException] for an HTTP failure).
  @override
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/otp/send',
        data: {'phone': phone, 'role': role, 'device_id': _deviceId},
        // Each send voids the previous code, so a 429 is never replayed.
        options: Options(extra: {RetryInterceptor.noRetryOn429: true}),
      );
      _logSend(response.requestOptions.uri, response.statusCode, null);
      final data = response.data;
      final refId = data is Map ? data['ref_id'] : null;
      if (data is! Map<String, dynamic> || refId is! String || refId.isEmpty) {
        throw const FormatException('OTP send: 200 without a ref_id');
      }
      return data;
    } on DioException catch (e) {
      final data = e.response?.data;
      _logSend(
        e.requestOptions.uri,
        e.response?.statusCode,
        data is Map ? data['code']?.toString() : e.type.name,
      );
      rethrow;
    }
  }

  /// URL, status and the backend `code` only — never the phone, code or ref_id.
  static void _logSend(Uri url, int? status, String? code) =>
      CrashReporting.breadcrumb(
        'OTP send: POST $url -> ${status ?? 'no response'}'
        '${code == null || code.isEmpty ? '' : ' $code'}',
      );

  @override
  Future<Map<String, dynamic>> sendVerifyOtp({
    required String phone,
    required String otp,
    required String role,
    required String refId,
    String? fullName,
  }) async {
    final response = await _dio.post(
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
