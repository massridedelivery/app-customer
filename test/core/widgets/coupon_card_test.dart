import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {String locale = 'th'}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: Locale(locale),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

const _data = CouponCardData(
  code: 'RIDE50',
  title: 'เรียกรถครั้งแรก ลด ฿50',
  description: 'ส่วนลดค่าโดยสาร',
  discountValue: '฿50',
  scope: PromoScope.ride,
);

void main() {
  testWidgets('browse mode: service stub, detail link, whole card taps', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(CouponCard(data: _data, onTap: () => tapped = true)),
    );
    expect(find.text('เรียกรถ'), findsOneWidget);
    expect(find.text('เรียกรถครั้งแรก ลด ฿50'), findsOneWidget);
    expect(find.text('ดูรายละเอียด ›'), findsOneWidget);
    expect(find.text('ใช้คูปอง'), findsNothing);
    await tester.tap(find.text('RIDE50'));
    expect(tapped, isTrue);
  });

  testWidgets('picker mode: the same ticket with apply, footer renders', (
    tester,
  ) async {
    var applied = false;
    var tapped = false;
    await tester.pumpWidget(
      _host(
        CouponCard(
          data: _data,
          onApply: () => applied = true,
          onCancel: () {},
          onTap: () => tapped = true,
          footer: const Text('สั่งเพิ่มอีก ฿20'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('couponStubLabel')), findsOneWidget);
    expect(find.text('ดูรายละเอียด ›'), findsNothing);
    expect(find.text('สั่งเพิ่มอีก ฿20'), findsOneWidget);
    // In a picker the card itself doesn't open anything.
    await tester.tap(find.text('RIDE50'));
    expect(tapped, isFalse);
    await tester.tap(find.text('ใช้คูปอง'));
    expect(applied, isTrue);
  });

  testWidgets('picker: a selected coupon offers cancel', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(
      _host(
        CouponCard(
          data: _data,
          isSelected: true,
          onApply: () {},
          onCancel: () => cancelled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยกเลิก'));
    expect(cancelled, isTrue);
  });

  testWidgets('English: stub, headline, minimum and action are English', (
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
      _host(
        CouponCard(data: data, onApply: () {}),
        locale: 'en',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('All services'), findsOneWidget);
    expect(find.text('20% off · Up to ฿100'), findsOneWidget);
    expect(find.text('Min. ฿150'), findsOneWidget);
    expect(find.text('Use'), findsOneWidget);
    expect(find.textContaining('ลด'), findsNothing);
  });

  testWidgets('free shipping is food, says ส่งฟรี', (tester) async {
    final data = CouponCardData.fromMap({
      'code': 'FREESHIP',
      'promo_type': 'free_shipping',
      'discount_type': 'percentage',
      'discount_value': 100,
      'min_order': 99,
      'applies_to': 'MESSENGER',
    });
    await tester.pumpWidget(_host(CouponCard(data: data, onTap: () {})));
    expect(find.text('ส่งอาหาร'), findsOneWidget);
    expect(find.text('ส่งฟรี'), findsOneWidget);
    expect(find.text('ขั้นต่ำ ฿99'), findsOneWidget);
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

  testWidgets('a custom action replaces the link', (tester) async {
    await tester.pumpWidget(
      _host(
        const CouponCard(
          data: _data,
          action: Text('ใช้เลย', key: Key('a')),
        ),
      ),
    );
    expect(find.byKey(const Key('a')), findsOneWidget);
    expect(find.text('ดูรายละเอียด ›'), findsNothing);
    expect(find.text('ใช้คูปอง'), findsNothing);
  });
}
