import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
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
      final th = lookupAppLocalizations(const Locale('th'));
      expect(PromoScope.all.label(th), 'ลดทั่วไป');
      expect(PromoScope.ride.label(th), 'เฉพาะเรียกรถ');
      expect(PromoScope.food.label(th), 'เฉพาะอาหาร');
      expect(PromoScope.messenger.label(th), 'เฉพาะส่งของ');
    });

    test('labels and tabs follow the language', () {
      final en = lookupAppLocalizations(const Locale('en'));
      expect(PromoScope.all.label(en), 'All services');
      expect(PromoScope.ride.label(en), 'Rides only');
      expect(PromoScope.food.label(en), 'Food only');
      expect(PromoScope.messenger.label(en), 'Messenger only');
      expect(PromoScope.ride.tabLabel(en), 'Ride');
      final th = lookupAppLocalizations(const Locale('th'));
      expect(PromoScope.all.tabLabel(th), 'ทั่วไป');
      expect(PromoScope.ride.tabLabel(th), 'เรียกรถ');
      expect(PromoScope.food.tabLabel(th), 'อาหาร');
      expect(PromoScope.messenger.tabLabel(th), 'ส่งของ');
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
      expect(d.freeShipping, isFalse);
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
      expect(d.freeShipping, isTrue);
      expect(d.discountValue, isEmpty);
      expect(d.maxDiscount, isNull);
      expect(d.scope, PromoScope.messenger);
      expect(d.color, promoColorOf({'promo_type': 'free_shipping'}));
    });
  });
}
