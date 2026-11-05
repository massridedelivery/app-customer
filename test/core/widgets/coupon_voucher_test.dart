import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A points coupon as GET /api/customer/promos/context lists it.
const _voucher = {
  'kind': 'VOUCHER',
  'voucher_id': 'v-1',
  'code': 'RW-7KQ2-M9XD',
  'title': 'ส่งฟรีค่าอาหาร',
  'discount_text': 'ส่งฟรี สูงสุด ฿40',
  'discount': {
    'type': 'FREE_DELIVERY',
    'value': 0,
    'max_discount': 40,
    'min_spend': 150,
    'applies_to': 'FOOD',
  },
  'applies_to': 'FOOD',
  'expires_at': '2026-12-01T16:59:00Z',
};

void main() {
  test('a points coupon from promos/context becomes a voucher card', () {
    final d = CouponCardData.fromMap(Map<String, dynamic>.from(_voucher));
    expect(d.isVoucher, isTrue);
    expect(d.freeShipping, isTrue);
    expect(d.minSpend, 150);
    expect(d.description, 'ส่งฟรี สูงสุด ฿40');
    expect(
      CouponCardData.fromMap({'code': 'NEW50', 'discount_value': 50}).isVoucher,
      isFalse,
    );
  });

  test('food parses a voucher with an object discount and no description', () {
    final p = PromoModel.fromJson(Map<String, dynamic>.from(_voucher));
    expect(p.isVoucher, isTrue);
    expect(p.code, 'RW-7KQ2-M9XD');
    expect(p.description, '');
    expect(p.discount, 0);
    expect(p.minOrder, 150);
    expect(CouponCardData.fromFoodPromo(p).description, 'ส่งฟรี สูงสุด ฿40');
  });

  testWidgets('the card says คูปองแลกคะแนน', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: Scaffold(
          body: CouponCard(
            data: CouponCardData.fromMap(Map<String, dynamic>.from(_voucher)),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('คูปองแลกคะแนน'), findsOneWidget);
  });
}
