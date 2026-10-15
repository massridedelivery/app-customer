/// Turning a promo-validate rejection into a message for the coupon screens,
/// in the app's current language. The backend reports a refused code either as
/// a non-2xx with a `message`/`error`, or as a 200 whose `applied[]` lacks the
/// code (optionally with a `rejected[]` entry carrying a `reason`). Its reasons
/// are English and unstable, so only well-known ones are mapped (to Thai in
/// Thai mode, to clean English otherwise); anything else falls back to a
/// generic line instead of showing the raw reason.
library;

import 'package:customer_app/core/localization/app_language.dart';

/// Generic "this coupon can't be used here" line, in the current language.
String get kPromoRejectedFallback => AppLanguage.l10n().promoRejectedFallback;

/// The message for a validate response that did not apply [code].
String promoRejectionMessage(Map<String, dynamic> response, String code) {
  final upper = code.toUpperCase();
  final rejected = response['rejected'];
  if (rejected is List) {
    for (final item in rejected) {
      if (item is! Map) continue;
      final itemCode = item['code']?.toString().toUpperCase();
      if (itemCode != null && itemCode != upper) continue;
      final reason = (item['reason'] ?? item['message'])?.toString();
      final mapped = promoReasonToThai(reason);
      if (mapped != null) return mapped;
    }
  }
  return promoReasonToThai(
        (response['message'] ?? response['error'])?.toString(),
      ) ??
      kPromoRejectedFallback;
}

/// Maps a known backend rejection reason to a message in the current
/// language (Thai in Thai mode, English otherwise; [languageCode] overrides);
/// null when unrecognised. A reason that is already Thai is returned as-is.
String? promoReasonToThai(String? reason, {String? languageCode}) {
  final raw = (reason ?? '').trim();
  if (raw.isEmpty) return null;
  if (RegExp(r'[฀-๿]').hasMatch(raw)) return raw;

  final l10n = AppLanguage.l10n(languageCode);
  final s = raw.toLowerCase();
  if (s.contains('new user') || s.contains('first')) {
    return l10n.promoRejectNewUser;
  }
  if (s.contains('expire')) return l10n.promoRejectExpired;
  if (s.contains('not started') || s.contains('not yet')) {
    return l10n.promoRejectNotStarted;
  }
  if (s.contains('limit') ||
      s.contains('already used') ||
      s.contains('used up')) {
    return l10n.promoRejectLimit;
  }
  if (s.contains('minimum') ||
      s.contains('min order') ||
      s.contains('min_spend')) {
    return l10n.promoRejectMinSpend;
  }
  if (s.contains('not found') ||
      s.contains('invalid code') ||
      s.contains('invalid promo')) {
    return l10n.promoRejectNotFound;
  }
  if (s.contains('not applicable') ||
      s.contains('scope') ||
      s.contains('service')) {
    return l10n.promoRejectWrongService;
  }
  return null;
}
