import 'package:customer_app/core/utils/promo_rejection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('promoReasonToThai · English mode', () {
    test('maps well-known reasons to English', () {
      expect(
        promoReasonToThai('Promo expired', languageCode: 'en'),
        'This coupon has expired',
      );
      expect(
        promoReasonToThai('minimum order not met', languageCode: 'en'),
        "Your order hasn't reached this coupon's minimum",
      );
      expect(promoReasonToThai('invalid request', languageCode: 'en'), isNull);
    });
  });

  group('promoReasonToThai', () {
    test('translates well-known reasons', () {
      expect(
        promoReasonToThai('promo is for new users only'),
        'คูปองนี้สำหรับลูกค้าใหม่เท่านั้น',
      );
      expect(promoReasonToThai('Promo expired'), 'คูปองนี้หมดอายุแล้ว');
      expect(
        promoReasonToThai('usage limit reached'),
        'คุณใช้สิทธิ์คูปองนี้ครบแล้ว',
      );
      expect(
        promoReasonToThai('minimum order not met'),
        'ยอดยังไม่ถึงขั้นต่ำของคูปองนี้',
      );
    });

    test('keeps a Thai reason as-is', () {
      expect(promoReasonToThai('คูปองหมดแล้ว'), 'คูปองหมดแล้ว');
    });

    test('returns null for unknown or empty reasons', () {
      expect(promoReasonToThai('invalid request'), isNull);
      expect(promoReasonToThai(''), isNull);
      expect(promoReasonToThai(null), isNull);
    });
  });

  group('promoRejectionMessage', () {
    test('uses the rejected entry for the requested code', () {
      final msg = promoRejectionMessage({
        'applied': [],
        'rejected': [
          {'code': 'OTHER', 'reason': 'expired'},
          {'code': 'RIDE50', 'reason': 'new users only'},
        ],
      }, 'ride50');
      expect(msg, 'คูปองนี้สำหรับลูกค้าใหม่เท่านั้น');
    });

    test('falls back to a generic Thai line instead of raw English', () {
      expect(
        promoRejectionMessage({'applied': []}, 'RIDE50'),
        kPromoRejectedFallback,
      );
      expect(
        promoRejectionMessage({'applied': [], 'message': 'nope'}, 'RIDE50'),
        kPromoRejectedFallback,
      );
    });
  });

  group('BE dev95 rejection reasons', () {
    test('fully redeemed / not available / minimum spend with amount (th)', () {
      expect(
        promoReasonToThai('promotion fully redeemed', languageCode: 'th'),
        'สิทธิ์ของโค้ดนี้เต็มแล้ว',
      );
      expect(
        promoReasonToThai(
          'promotion not available at this time',
          languageCode: 'th',
        ),
        'โค้ดนี้ใช้ไม่ได้ในขณะนี้',
      );
      expect(
        promoReasonToThai('minimum spend 150 required', languageCode: 'th'),
        'ยอดขั้นต่ำ ฿150 จึงจะใช้โค้ดนี้ได้',
      );
      expect(
        promoReasonToThai('usage limit reached per user', languageCode: 'th'),
        'คุณใช้สิทธิ์คูปองนี้ครบแล้ว',
      );
    });

    test('same reasons in English', () {
      expect(
        promoReasonToThai('promotion fully redeemed', languageCode: 'en'),
        'This code has been fully redeemed',
      );
      expect(
        promoReasonToThai('minimum spend 1,000.00 required', languageCode: 'en'),
        'Spend at least ฿1000 to use this code',
      );
    });
  });
}
