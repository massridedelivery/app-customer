import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
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
