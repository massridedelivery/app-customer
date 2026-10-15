import 'package:customer_app/features/messenger/presentation/screens/messenger_coupon_screen.dart';
import 'package:customer_app/features/messenger/presentation/screens/messenger_review_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home, String lang, {List overrides = const []}) {
  return ProviderScope(
    overrides: [...overrides],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(lang),
      home: home,
    ),
  );
}

void main() {
  group('messenger strings', () {
    test('English mode gets English price summary + CTA', () {
      final en = lookupAppLocalizations(const Locale('en'));
      expect(en.msgrTotal, 'Total');
      expect(en.msgrSizeFee, 'Size fee');
      expect(en.msgrExpressFee, 'Express fee');
      expect(en.msgrCallMessengerPrice('120'), 'Book messenger • ฿120');
      expect(en.msgrRecipientNameRequired, "Please enter the recipient's name");
      expect(
        en.msgrSizeTierLimits('5', '40', '30', '30'),
        '≤ 5 kg\n40×30×30 cm',
      );
    });

    test('Thai mode keeps the exact original wording', () {
      final th = lookupAppLocalizations(const Locale('th'));
      expect(th.msgrTotal, 'ยอดชำระ');
      expect(th.msgrDeliveryFee, 'ค่าส่ง');
      expect(th.msgrSizeFee, 'ค่าธรรมเนียมขนาด');
      expect(th.msgrExpressFee, 'ค่าส่งด่วน');
      expect(th.msgrCallMessengerPrice('120'), 'เรียกเมสเซนเจอร์ • ฿120');
      expect(th.msgrRecipientNameRequired, 'กรุณาระบุชื่อผู้รับ');
      expect(
        th.msgrSizeTierLimits('5', '40', '30', '30'),
        '≤ 5 กก.\n40×30×30 ซม.',
      );
      expect(th.msgrRated('4'), 'ให้คะแนนแล้ว  ⭐ 4');
    });
  });

  group('MessengerReviewScreen', () {
    testWidgets('renders English and localizes the missing-rating error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const MessengerReviewScreen(orderId: 'm1'), 'en'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rate delivery'), findsOneWidget);
      expect(find.text('How was your driver?'), findsOneWidget);
      expect(find.text('Submit review'), findsOneWidget);

      await tester.tap(find.text('Submit review'));
      await tester.pump();
      expect(find.text('Please rate your driver first'), findsOneWidget);
      expect(find.text('RATING_REQUIRED'), findsNothing);
    });

    testWidgets('keeps the Thai missing-rating error in Thai mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const MessengerReviewScreen(orderId: 'm1'), 'th'),
      );
      await tester.pumpAndSettle();

      expect(find.text('ส่งรีวิว'), findsOneWidget);
      await tester.tap(find.text('ส่งรีวิว'));
      await tester.pump();
      expect(find.text('กรุณาให้คะแนนคนขับก่อนนะครับ'), findsOneWidget);
    });
  });

  testWidgets('MessengerCouponScreen renders English in en', (tester) async {
    await tester.pumpWidget(
      _app(
        const MessengerCouponScreen(),
        'en',
        overrides: [
          promoListProvider.overrideWith((ref) async => <dynamic>[]),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose a promo code'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('No promo codes yet'), findsOneWidget);
  });
}
