import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';

import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 11, 28, 5);

Future<void> _pump(
  WidgetTester tester,
  Map<String, dynamic> promo, {
  VoidCallback? onTap,
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width * 3, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('th'),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CouponCard(
            data: CouponCardData.fromMap(promo),
            onTap: onTap,
            now: _now,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the stub names the service; free delivery has its own', (
    tester,
  ) async {
    const cases = {
      'RIDE': 'เรียกรถ',
      'FOOD': 'ส่งอาหาร',
      'MESSENGER': 'ส่งของ',
      'ALL': 'ทุกบริการ',
    };
    for (final e in cases.entries) {
      await _pump(tester, {
        'code': 'X',
        'discount_type': 'fixed',
        'discount_value': 20,
        'applies_to': e.key,
      });
      expect(
        tester.widget<Text>(find.byKey(const Key('couponStubLabel'))).data,
        e.value,
      );
    }
    await _pump(tester, {
      'code': 'FREE',
      'promo_type': 'free_shipping',
      'discount_type': 'percentage',
      'discount_value': 100,
      'applies_to': 'ALL',
    });
    expect(
      tester.widget<Text>(find.byKey(const Key('couponStubLabel'))).data,
      'ส่งฟรี',
    );
  });

  testWidgets('shows what it gives, the minimum and time left', (tester) async {
    await _pump(tester, {
      'code': 'DIS30',
      'discount_type': 'percentage',
      'discount_value': 30,
      'max_discount': 30,
      'min_order': 100,
      'applies_to': 'RIDE',
      'valid_until': '2026-12-01T16:59:00Z',
    });
    expect(find.text('DIS30'), findsOneWidget);
    expect(find.text('ลด 30% · สูงสุด ฿30'), findsOneWidget);
    final meta = tester.widget<Text>(find.byKey(const Key('couponMeta')));
    expect(meta.textSpan!.toPlainText(), 'ขั้นต่ำ ฿100 · เหลือ 3 วัน');
    expect(find.text('ใช้ถึง 1 ธ.ค. 2569'), findsOneWidget);
  });

  testWidgets('no minimum, and no countdown more than a week out', (
    tester,
  ) async {
    await _pump(tester, {
      'code': 'NEW50',
      'title': 'ส่วนลด ฿50 ลูกค้าใหม่',
      'discount_type': 'fixed',
      'discount_value': 50,
      'applies_to': 'ALL',
      'valid_until': '2026-12-31T16:59:00Z',
    });
    expect(find.text('ส่วนลด ฿50 ลูกค้าใหม่'), findsOneWidget);
    final meta = tester.widget<Text>(find.byKey(const Key('couponMeta')));
    expect(meta.textSpan!.toPlainText(), 'ไม่มีขั้นต่ำ');
  });

  test('time left: days, then hours, nothing when ended or far off', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('th'));
    expect(
      promoTimeLeft(_now.add(const Duration(hours: 5)), l10n, now: _now),
      'เหลือ 5 ชม.',
    );
    expect(
      promoTimeLeft(
        _now.add(const Duration(days: 2, hours: 3)),
        l10n,
        now: _now,
      ),
      'เหลือ 2 วัน',
    );
    expect(
      promoTimeLeft(_now.add(const Duration(days: 8)), l10n, now: _now),
      isNull,
    );
    expect(
      promoTimeLeft(_now.subtract(const Duration(hours: 1)), l10n, now: _now),
      isNull,
    );
    expect(promoTimeLeft(null, l10n, now: _now), isNull);
  });

  testWidgets(
    '"ดูรายละเอียด" stays on one line on a narrow phone and opens it',
    (tester) async {
      var taps = 0;
      await _pump(
        tester,
        {
          'code': 'NEW50',
          'discount_type': 'fixed',
          'discount_value': 50,
          'applies_to': 'ALL',
          'valid_until': '2026-12-31T16:59:00Z',
        },
        onTap: () => taps++,
        width: 320,
      );
      expect(tester.takeException(), isNull);
      final link = find.byKey(const Key('couponDetails'));
      final box = tester.getSize(link);
      expect(box.height, lessThan(24));
      await tester.tap(find.text('NEW50'));
      expect(taps, 1);
    },
  );

  test('stub colours: ride and all red, food orange, parcel blue', () {
    expect(PromoScope.ride.stubColor, const Color(0xFFC8323F));
    expect(PromoScope.all.stubColor, const Color(0xFFC8323F));
    expect(PromoScope.food.stubColor, const Color(0xFFE2855A));
    expect(PromoScope.messenger.stubColor, const Color(0xFF2F6FD6));
    expect(kFreeDeliveryStubColor, const Color(0xFF13A08F));
  });
}
