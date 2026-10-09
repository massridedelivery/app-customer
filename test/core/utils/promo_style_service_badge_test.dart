import 'package:customer_app/core/utils/promo_style.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the home service-card badge is derived from real promo data.
///
/// The backend promo list returns `applies_to` ("ALL"|"RIDE"|"FOOD"|
/// "MESSENGER") plus `promo_type`/`discount_value` (see promo.Promotion), so
/// these cases use that real shape. The right badge shows for the right
/// service, the strongest offer wins, "ALL" covers every service, and a service
/// with no matching promo shows no badge (null).
void main() {
  group('serviceBadgeOf', () {
    test('no promos → every service shows no badge', () {
      expect(serviceBadgeOf(const [], 'ride'), isNull);
      expect(serviceBadgeOf(const [], 'food'), isNull);
      expect(serviceBadgeOf(const [], 'messenger'), isNull);
    });

    test('applies_to RIDE badges only the ride card', () {
      final promos = [
        {'applies_to': 'RIDE', 'promo_type': 'fixed', 'discount_value': 50},
      ];
      expect(serviceBadgeOf(promos, 'ride')!.text, 'ลด ฿50*');
      expect(serviceBadgeOf(promos, 'food'), isNull);
      expect(serviceBadgeOf(promos, 'messenger'), isNull);
    });

    test('applies_to ALL covers every service', () {
      final promos = [
        {'applies_to': 'ALL', 'promo_type': 'fixed', 'discount_value': 25},
      ];
      expect(serviceBadgeOf(promos, 'ride')!.text, 'ลด ฿25*');
      expect(serviceBadgeOf(promos, 'food')!.text, 'ลด ฿25*');
      expect(serviceBadgeOf(promos, 'messenger')!.text, 'ลด ฿25*');
    });

    test('free shipping shows "ส่งฟรี*"', () {
      final promos = [
        {'applies_to': 'FOOD', 'promo_type': 'free_shipping'},
      ];
      expect(serviceBadgeOf(promos, 'food')!.text, 'ส่งฟรี*');
    });

    test('percentage discount renders as a percent badge', () {
      final promos = [
        {'applies_to': 'MESSENGER', 'promo_type': 'percentage', 'discount_value': 20},
      ];
      expect(serviceBadgeOf(promos, 'messenger')!.text, 'ลด 20%*');
    });

    test('strongest offer wins when several promos match a service', () {
      final promos = [
        {'applies_to': 'RIDE', 'promo_type': 'fixed', 'discount_value': 30},
        {'applies_to': 'RIDE', 'promo_type': 'fixed', 'discount_value': 80},
      ];
      expect(serviceBadgeOf(promos, 'ride')!.text, 'ลด ฿80*');
    });

    test('free shipping outranks a fixed discount on the same service', () {
      final promos = [
        {'applies_to': 'FOOD', 'promo_type': 'fixed', 'discount_value': 99},
        {'applies_to': 'FOOD', 'promo_type': 'free_shipping'},
      ];
      expect(serviceBadgeOf(promos, 'food')!.text, 'ส่งฟรี*');
    });

    test('a FOOD promo never leaks onto the ride card', () {
      final promos = [
        {'applies_to': 'FOOD', 'promo_type': 'fixed', 'discount_value': 60},
      ];
      expect(serviceBadgeOf(promos, 'ride'), isNull);
    });

    test('keyword fallback applies only when applies_to is absent', () {
      final promos = [
        {'tag': 'เดินทาง', 'promo_type': 'fixed', 'discount_value': 60},
      ];
      expect(serviceBadgeOf(promos, 'ride')!.text, 'ลด ฿60*');
      expect(serviceBadgeOf(promos, 'food'), isNull);
    });
  });
}
