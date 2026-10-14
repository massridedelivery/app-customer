/// Turning a promo-validate rejection into a Thai message for the coupon
/// screens. The backend reports a refused code either as a non-2xx with a
/// `message`/`error`, or as a 200 whose `applied[]` lacks the code (optionally
/// with a `rejected[]` entry carrying a `reason`). Its reasons are English and
/// unstable, so only well-known ones are translated; anything else falls back
/// to a generic line instead of showing raw English.
library;

const String kPromoRejectedFallback = 'ใช้คูปองนี้กับรายการนี้ไม่ได้';

/// The Thai message for a validate response that did not apply [code].
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

/// Maps a known backend rejection reason to Thai; null when unrecognised.
/// A reason that is already Thai is returned as-is.
String? promoReasonToThai(String? reason) {
  final raw = (reason ?? '').trim();
  if (raw.isEmpty) return null;
  if (RegExp(r'[฀-๿]').hasMatch(raw)) return raw;

  final s = raw.toLowerCase();
  if (s.contains('new user') || s.contains('first')) {
    return 'คูปองนี้สำหรับลูกค้าใหม่เท่านั้น';
  }
  if (s.contains('expire')) return 'คูปองนี้หมดอายุแล้ว';
  if (s.contains('not started') || s.contains('not yet')) {
    return 'คูปองนี้ยังไม่เริ่มใช้งาน';
  }
  if (s.contains('limit') ||
      s.contains('already used') ||
      s.contains('used up')) {
    return 'คุณใช้สิทธิ์คูปองนี้ครบแล้ว';
  }
  if (s.contains('minimum') ||
      s.contains('min order') ||
      s.contains('min_spend')) {
    return 'ยอดยังไม่ถึงขั้นต่ำของคูปองนี้';
  }
  if (s.contains('not found') ||
      s.contains('invalid code') ||
      s.contains('invalid promo')) {
    return 'ไม่พบรหัสคูปองนี้';
  }
  if (s.contains('not applicable') ||
      s.contains('scope') ||
      s.contains('service')) {
    return 'คูปองนี้ใช้กับบริการนี้ไม่ได้';
  }
  return null;
}
