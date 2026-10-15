import 'package:customer_app/features/home/presentation/widgets/home_promo_banner.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _promos = <dynamic>[
  {
    'id': '1',
    'code': 'RIDE50',
    'title': 'Ride promo',
    'promo_type': 'fixed',
    'discount_value': 50,
    'min_order': 100,
  },
  {'id': '2', 'code': 'SHIPFREE', 'promo_type': 'free_shipping'},
];

Widget _host(String locale) => ProviderScope(
  overrides: [promoListProvider.overrideWith((ref) async => _promos)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale(locale),
    home: const Scaffold(body: SingleChildScrollView(child: HomePromoBanner())),
  ),
);

void main() {
  testWidgets('Thai: header, headlines and min spend stay Thai', (
    tester,
  ) async {
    await tester.pumpWidget(_host('th'));
    await tester.pumpAndSettle();
    expect(find.text('โปรโมชั่นสำหรับคุณ'), findsOneWidget);
    expect(find.text('ดูทั้งหมด'), findsOneWidget);
    expect(find.text('ลด ฿50'), findsOneWidget);
    expect(find.text('Ride promo · ขั้นต่ำ ฿100'), findsOneWidget);
    expect(find.text('ส่งฟรี'), findsOneWidget);
    // A promo without a title falls back to "โปรโมชั่น".
    expect(find.text('โปรโมชั่น'), findsOneWidget);
  });

  testWidgets('English: header, headlines and min spend are English', (
    tester,
  ) async {
    await tester.pumpWidget(_host('en'));
    await tester.pumpAndSettle();
    expect(find.text('Promotions for you'), findsOneWidget);
    expect(find.text('See All'), findsOneWidget);
    expect(find.text('฿50 off'), findsOneWidget);
    expect(find.text('Ride promo · Min. ฿100'), findsOneWidget);
    expect(find.text('Free Delivery'), findsOneWidget);
    expect(find.text('Promotion'), findsOneWidget);
  });
}
