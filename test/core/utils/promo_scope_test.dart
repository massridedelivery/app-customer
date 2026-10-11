import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromoScope.fromAppliesTo', () {
    test('maps the backend applies_to values', () {
      expect(PromoScope.fromAppliesTo('ALL'), PromoScope.all);
      expect(PromoScope.fromAppliesTo('RIDE'), PromoScope.ride);
      expect(PromoScope.fromAppliesTo('food'), PromoScope.food);
      expect(PromoScope.fromAppliesTo(' MESSENGER '), PromoScope.messenger);
    });

    test('missing or unknown values count as all', () {
      expect(PromoScope.fromAppliesTo(null), PromoScope.all);
      expect(PromoScope.fromAppliesTo(''), PromoScope.all);
      expect(PromoScope.fromAppliesTo('MART'), PromoScope.all);
    });

    test('labels are text only', () {
      expect(PromoScope.all.label, 'ลดทั่วไป');
      expect(PromoScope.ride.label, 'เฉพาะเรียกรถ');
      expect(PromoScope.food.label, 'เฉพาะอาหาร');
      expect(PromoScope.messenger.label, 'เฉพาะส่งของ');
    });
  });

  group('CouponCardData.fromMap', () {
    test('fixed promo: red stub, baht value, scope from applies_to', () {
      final d = CouponCardData.fromMap({
        'code': 'RIDE50',
        'title': 'เรียกรถครั้งแรก ลด ฿50',
        'discount_type': 'fixed',
        'discount_value': 50,
        'applies_to': 'RIDE',
      });
      expect(d.discountValue, '฿50');
      expect(d.stubPrefix, 'ลด');
      expect(d.scope, PromoScope.ride);
      expect(d.color, promoColorOf({'discount_type': 'fixed'}));
    });

    test('free shipping shows "ส่งฟรี", not "ลด 100%"', () {
      final d = CouponCardData.fromMap({
        'code': 'FREESHIP',
        'promo_type': 'free_shipping',
        'discount_type': 'percentage',
        'discount_value': 100,
        'max_discount': 40,
        'applies_to': 'MESSENGER',
      });
      expect(d.discountValue, 'ส่งฟรี');
      expect(d.stubPrefix, '');
      expect(d.subDiscount, isNull);
      expect(d.scope, PromoScope.messenger);
      expect(d.color, promoColorOf({'promo_type': 'free_shipping'}));
    });
  });
}
