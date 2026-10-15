import 'package:customer_app/features/auth/data/datasources/email_otp_data_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in account's email (`GET /auth/email`).
class AccountEmail {
  const AccountEmail({required this.email, required this.verified});

  /// Empty when the account has none yet.
  final String email;

  /// Only a verified email can be used to sign in to this account.
  final bool verified;

  bool get isEmpty => email.isEmpty;

  factory AccountEmail.fromJson(Map<String, dynamic> json) => AccountEmail(
    email: (json['email'] ?? '').toString().trim(),
    verified: json['verified'] == true,
  );
}

/// Null hides the profile's email row: email login is switched off (503
/// EMAIL_LOGIN_UNAVAILABLE on prod for now) or the backend can't say.
final accountEmailProvider = FutureProvider.autoDispose<AccountEmail?>((
  ref,
) async {
  try {
    final json = await ref.read(emailOtpDataSourceProvider).accountEmail();
    return AccountEmail.fromJson(json);
  } catch (_) {
    return null;
  }
});
