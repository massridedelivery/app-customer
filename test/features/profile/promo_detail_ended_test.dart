import 'package:customer_app/features/profile/presentation/screens/promo_detail_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _promo({required bool active}) => {
  'id': 'p1',
  'code': 'DIS50',
  'title': 'ลดเพิ่มพิเศษช่วงเปิดบริการ',
  'promo_type': 'fixed',
  'discount_value': 50,
  'applies_to': 'ALL',
  'is_active': active,
  'expires_at': '2026-12-31T16:59:59Z',
};

Future<void> _pump(WidgetTester tester, Map<String, dynamic> promo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        promoDetailProvider('p1').overrideWith((ref) async => promo),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('th'),
        home: PromoDetailScreen(promoId: 'p1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an ended promo (is_active false) says so', (tester) async {
    await _pump(tester, _promo(active: false));
    expect(find.byKey(const Key('promoEndedBanner')), findsOneWidget);
    expect(find.text('โปรนี้สิ้นสุดแล้ว'), findsOneWidget);
  });

  testWidgets('an active promo has no ended banner', (tester) async {
    await _pump(tester, _promo(active: true));
    expect(find.byKey(const Key('promoEndedBanner')), findsNothing);
  });
}
