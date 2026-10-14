import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why the backend refused this account. Any authenticated call — and the
/// auth calls themselves (OTP send/verify, email OTP, refresh, login) — can
/// answer 403 with `{"code": "account_suspended"}` or `{"code":
/// "account_deleted"}`. Retrying or refreshing the token can't fix either.
enum AccountBlock {
  suspended,
  deleted;

  static AccountBlock? fromCode(Object? code) => switch (code) {
    'account_suspended' => AccountBlock.suspended,
    'account_deleted' => AccountBlock.deleted,
    _ => null,
  };
}

/// The block a failed response carries, or null for any other error.
AccountBlock? accountBlockOf(Response<dynamic>? response) {
  if (response?.statusCode != 403) return null;
  final data = response!.data;
  return data is Map ? AccountBlock.fromCode(data['code']) : null;
}

/// Set once a 403 account block comes back; the router then holds the app on
/// the "account suspended/deleted" screen until the user dismisses it.
class AccountBlockNotifier extends Notifier<AccountBlock?> {
  @override
  AccountBlock? build() => null;

  void block(AccountBlock reason) => state = reason;

  void clear() => state = null;
}

final accountBlockProvider =
    NotifierProvider<AccountBlockNotifier, AccountBlock?>(
      AccountBlockNotifier.new,
    );
