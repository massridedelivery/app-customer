abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Why `POST /auth/otp/send` didn't hand back a code.
enum OtpSendError {
  /// 400 (INVALID_PHONE or a bad body): fix the number, stay on the phone screen.
  invalidPhone,

  /// 403 account_suspended / account_deleted: the account-blocked screen takes over.
  accountBlocked,

  /// 429 OTP_RATE_LIMITED: wait [OtpSendFailure.retryAfter] seconds; never auto-retried.
  rateLimited,

  /// 500: the SMS provider refused the send.
  sendFailed,

  /// No answer: offline, DNS, timeout.
  network,

  /// Anything else (404, 502, a 200 without a ref_id, an unreadable body).
  server,
}

/// A failed OTP send. [message] is the server's own `error` text when it sent
/// one (shown as is), otherwise empty and the UI picks the wording.
class OtpSendFailure extends Failure {
  const OtpSendFailure(
    this.kind, {
    String message = '',
    this.retryAfter = 0,
    this.status,
    this.code,
  }) : super(message);

  final OtpSendError kind;

  /// Seconds until a new send is allowed (429 only).
  final int retryAfter;
  final int? status;
  final String? code;
}
