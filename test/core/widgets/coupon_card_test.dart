import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {String locale = 'th'}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: Locale(locale),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _data = CouponCardData(
  code: 'RIDE50',
  title: 'เรียกรถครั้งแรก ลด ฿50',
  description: 'ส่วนลดค่าโดยสาร',
  discountValue: '฿50',
  scope: PromoScope.ride,
);

void main() {
  testWidgets('browse mode: scope label, detail link, whole card taps', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(CouponCard(data: _data, onTap: () => tapped = true)),
    );
    expect(find.text('เฉพาะเรียกรถ'), findsOneWidget);
    expect(find.text('ดูรายละเอียด ›'), findsOneWidget);
    expect(find.text('ใช้คูปอง'), findsNothing);

    await tester.tap(find.text('RIDE50'));
    expect(tapped, isTrue);
  });

  testWidgets('picker mode: apply fires, footer renders', (tester) async {
    var applied = false;
    await tester.pumpWidget(
      _host(
        CouponCard(
          data: _data,
          onApply: () => applied = true,
          onCancel: () {},
          footer: const Text('สั่งเพิ่มอีก ฿20'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('สั่งเพิ่มอีก ฿20'), findsOneWidget);
    await tester.tap(find.text('ใช้คูปอง'));
    expect(applied, isTrue);
  });

  testWidgets('English: scope label, detail link and stub are English', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(CouponCard(data: _data, onTap: () {}), locale: 'en'),
    );
    expect(find.text('Rides only'), findsOneWidget);
    expect(find.text('View details ›'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('เฉพาะเรียกรถ'), findsNothing);
    expect(find.text('ลด'), findsNothing);
  });

  testWidgets('English: picker shows "Use", min spend and max discount', (
    tester,
  ) async {
    final data = CouponCardData.fromMap({
      'code': 'PCT20',
      'discount_type': 'percentage',
      'discount_value': 20,
      'max_discount': 100,
      'min_order': 150,
      'applies_to': 'ALL',
    });
    await tester.pumpWidget(
      _host(CouponCard(data: data, onApply: () {}), locale: 'en'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Use'), findsOneWidget);
    expect(find.text('Min. ฿150'), findsOneWidget);
    expect(find.text('Up to ฿100'), findsOneWidget);
    expect(find.text('All services'), findsOneWidget);
    // No title in the payload → localized default title.
    expect(find.text('Promotion'), findsOneWidget);
  });

  testWidgets('Thai: free shipping stub and default title keep Thai text', (
    tester,
  ) async {
    final data = CouponCardData.fromMap({
      'code': 'FREESHIP',
      'promo_type': 'free_shipping',
      'discount_type': 'percentage',
      'discount_value': 100,
      'min_order': 99,
      'applies_to': 'MESSENGER',
    });
    await tester.pumpWidget(_host(CouponCard(data: data, onTap: () {})));
    expect(find.text('ส่งฟรี'), findsOneWidget);
    expect(find.text('ลด'), findsNothing);
    expect(find.text('ขั้นต่ำ ฿99'), findsOneWidget);
    // Free delivery is food-only, even on a promo scoped to messenger.
    expect(find.text('เฉพาะอาหาร'), findsOneWidget);
    expect(find.text('โปรโมชั่น'), findsOneWidget);
  });

  testWidgets('disabled card cannot be applied', (tester) async {
    var applied = false;
    await tester.pumpWidget(
      _host(
        CouponCard(
          data: _data,
          isEnabled: false,
          onApply: () => applied = true,
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ใช้คูปอง'), warnIfMissed: false);
    expect(applied, isFalse);
  });
}
