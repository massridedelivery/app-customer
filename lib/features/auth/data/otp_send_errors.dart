import 'package:customer_app/core/error/failures.dart';
import 'package:dio/dio.dart';

/// Maps a failed `POST /auth/otp/send` to what the user is shown. Every
/// status lands on an [OtpSendError] — none is dropped.
OtpSendFailure otpSendFailureOf(DioException e) {
  final res = e.response;
  if (res == null) return const OtpSendFailure(OtpSendError.network);

  final status = res.statusCode ?? 0;
  final data = res.data;
  final code = data is Map ? data['code']?.toString() : null;
  final error = data is Map ? data['error'] : null;
  final text = error is String ? error.trim() : '';

  final kind = switch (status) {
    400 => OtpSendError.invalidPhone,
    403 when code == 'account_suspended' || code == 'account_deleted' =>
      OtpSendError.accountBlocked,
    429 => OtpSendError.rateLimited,
    500 => OtpSendError.sendFailed,
    _ => OtpSendError.server,
  };
  return OtpSendFailure(
    kind,
    // Only these two carry text meant for the user; a 500's "failed to send
    // OTP" and a proxy's HTML page are not.
    message:
        kind == OtpSendError.invalidPhone || kind == OtpSendError.rateLimited
        ? text
        : '',
    retryAfter: kind == OtpSendError.rateLimited ? _retryAfter(res) : 0,
    status: status,
    code: code,
  );
}

/// `retry_after` from the body, else the `Retry-After` header (seconds), else
/// a minute.
int _retryAfter(Response<dynamic> res) {
  final data = res.data;
  final fromBody = data is Map ? _seconds(data['retry_after']) : null;
  final seconds = fromBody ?? _seconds(res.headers.value('retry-after')) ?? 60;
  return seconds.clamp(1, 24 * 60 * 60);
}

int? _seconds(Object? v) => switch (v) {
  num n => n.ceil(),
  String s => int.tryParse(s.trim()),
  _ => null,
};
