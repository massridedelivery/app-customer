import 'dart:io' show Platform;

import 'package:customer_app/core/data/install_id.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Email one-time-code login (`/auth/otp/email/*`) and the SMS delivery check
/// (`/auth/otp/status`). Errors are left as [DioException]s for the caller to
/// branch on `code`.
class EmailOtpDataSource {
  EmailOtpDataSource(this._api, this._deviceId);

  final ApiService _api;
  final String _deviceId;

  static const _role = 'customer';

  /// `{message, ref_id, is_registered}`
  Future<Map<String, dynamic>> send(String email) async {
    final res = await _api.dio.post(
      '/auth/otp/email/send',
      data: {'email': email, 'role': _role, 'device_id': _deviceId},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// `{access_token, refresh_token, expires_in}` — the backend creates the
  /// customer account on the spot when the email has none.
  Future<Map<String, dynamic>> verify({
    required String email,
    required String otp,
    required String refId,
  }) async {
    final res = await _api.dio.post(
      '/auth/otp/email/verify',
      data: {
        'email': email,
        'otp': otp,
        'ref_id': refId,
        'role': _role,
        'device_id': _deviceId,
        'os': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
        if (!kIsWeb) 'os_version': Platform.operatingSystemVersion,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// `{channel, outcome, delivery, email_fallback}` for an SMS OTP [refId].
  Future<Map<String, dynamic>> smsStatus(String refId) async {
    final res = await _api.dio.get(
      '/auth/otp/status',
      queryParameters: {'ref_id': refId},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}

final emailOtpDataSourceProvider = Provider<EmailOtpDataSource>(
  (ref) => EmailOtpDataSource(
    ref.watch(apiServiceProvider),
    ref.watch(installIdProvider),
  ),
);
