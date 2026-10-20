import 'package:customer_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(List<dynamic> promos) => ProviderScope(
  overrides: [promoListProvider.overrideWith((ref) async => promos)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('th'),
    home: const OnboardingScreen(),
  ),
);

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('onboardingNext')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('four pages, no skip, last button reads "เริ่มต้นใช้งาน"', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    expect(find.text('เรียกรถได้ในไม่กี่แตะ'), findsOneWidget);
    expect(find.text('ข้าม'), findsNothing);
    expect(find.text('ถัดไป'), findsOneWidget);

    await _next(tester);
    expect(find.text('ส่งของ ส่งพัสดุ'), findsOneWidget);
    await _next(tester);
    expect(find.text('รู้ว่าใครมารับ ติดตามได้ตลอดทาง'), findsOneWidget);
    await _next(tester);
    expect(find.text('พร้อมใช้งานแล้ว!'), findsOneWidget);
    expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
    expect(find.text('ข้าม'), findsNothing);
    // No live promo → no coupon on the ready page.
    expect(find.text('สำหรับการเรียกรถ'), findsNothing);
  });

  testWidgets('ready page shows the best live ride promo', (tester) async {
    await tester.pumpWidget(
      _host(const [
        {'applies_to': 'ALL', 'promo_type': 'fixed', 'discount_value': 50},
        {'applies_to': 'ALL', 'promo_type': 'free_shipping'},
      ]),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await _next(tester);
    }
    // Free delivery is food-only, so rides get the ฿50 discount.
    expect(find.text('ลด ฿50*'), findsOneWidget);
    expect(find.text('สำหรับการเรียกรถ'), findsOneWidget);
  });
}
