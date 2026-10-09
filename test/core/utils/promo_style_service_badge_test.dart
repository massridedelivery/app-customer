import 'package:customer_app/core/utils/promo_style.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the home service-card badge is derived from real promo data:
/// the right badge shows for the right service, the strongest offer wins, and
/// a service with no matching promo shows no badge (null).
void main() {
  group('serviceBadgeOf', () {
    test('no promos → every service shows no badge', () {
      expect(serviceBadgeOf(const [], 'ride'), isNull);
      expect(serviceBadgeOf(const [], 'food'), isNull);
      expect(serviceBadgeOf(const [], 'messenger'), isNull);
    });

    test('structured service field maps a fixed discount to the ride card', () {
      final promos = [
        {'service': 'ride', 'discount_type': 'fixed', 'discount_value': 50},
      ];
      final badge = serviceBadgeOf(promos, 'ride');
      expect(badge, isNotNull);
      expect(badge!.text, 'ลด ฿50*');
      // Other services get nothing from a ride-only promo.
      expect(serviceBadgeOf(promos, 'food'), isNull);
      expect(serviceBadgeOf(promos, 'messenger'), isNull);
    });

    test('free shipping shows "ส่งฟรี*"', () {
      final promos = [
        {'service': 'food', 'promo_type': 'free_shipping'},
      ];
      expect(serviceBadgeOf(promos, 'food')!.text, 'ส่งฟรี*');
    });

    test('percentage discount renders as a percent badge', () {
      final promos = [
        {'services': ['messenger'], 'promo_type': 'percentage', 'discount_value': 20},
      ];
      expect(serviceBadgeOf(promos, 'messenger')!.text, 'ลด 20%*');
    });

    test('strongest offer wins when several promos match a service', () {
      final promos = [
        {'service': 'ride', 'discount_type': 'fixed', 'discount_value': 30},
        {'service': 'ride', 'discount_type': 'fixed', 'discount_value': 80},
      ];
      expect(serviceBadgeOf(promos, 'ride')!.text, 'ลด ฿80*');
    });

    test('free shipping outranks a fixed discount on the same service', () {
      final promos = [
        {'service': 'food', 'discount_type': 'fixed', 'discount_value': 99},
        {'service': 'food', 'promo_type': 'free_shipping'},
      ];
      expect(serviceBadgeOf(promos, 'food')!.text, 'ส่งฟรี*');
    });

    test('keyword fallback: a Thai "เดินทาง" tag maps to the ride card', () {
      final promos = [
        {'tag': 'เดินทาง', 'discount_type': 'fixed', 'discount_value': 60},
      ];
      expect(serviceBadgeOf(promos, 'ride')!.text, 'ลด ฿60*');
      expect(serviceBadgeOf(promos, 'food'), isNull);
    });

    test('an unrelated promo produces no badge on any service card', () {
      final promos = [
        {'title': 'สมัครสมาชิกรับแต้ม', 'discount_type': 'fixed', 'discount_value': 10},
      ];
      expect(serviceBadgeOf(promos, 'ride'), isNull);
      expect(serviceBadgeOf(promos, 'food'), isNull);
      expect(serviceBadgeOf(promos, 'messenger'), isNull);
    });
  });
}
