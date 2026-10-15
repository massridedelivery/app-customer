import 'package:customer_app/core/auth/account_block.dart';
import 'package:customer_app/core/data/support_config_provider.dart';
import 'package:customer_app/features/auth/presentation/screens/account_blocked_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Blocked extends AccountBlockNotifier {
  _Blocked(this.reason);

  final AccountBlock reason;

  @override
  AccountBlock? build() => reason;
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  AccountBlock reason = AccountBlock.suspended,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountBlockProvider.overrideWith(() => _Blocked(reason)),
        supportPhoneProvider.overrideWith((ref) async => '02-000-0000'),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const AccountBlockedScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('suspended account renders in Thai', (tester) async {
    await _pump(tester, locale: const Locale('th'));

    expect(find.text('บัญชีนี้ถูกระงับ'), findsOneWidget);
    expect(find.text('ติดต่อเจ้าหน้าที่ 02-000-0000'), findsOneWidget);
    expect(find.text('โทรหาเจ้าหน้าที่'), findsOneWidget);
    expect(find.text('ตกลง'), findsOneWidget);
  });

  testWidgets('suspended account renders in English', (tester) async {
    await _pump(tester, locale: const Locale('en'));

    expect(find.text('Account suspended'), findsOneWidget);
    expect(find.text('Contact support 02-000-0000'), findsOneWidget);
    expect(find.text('Call support'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.textContaining(RegExp('[\\u0E00-\\u0E7F]')), findsNothing);
  });

  testWidgets('deleted account renders in English', (tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      reason: AccountBlock.deleted,
    );

    expect(find.text('Account deleted'), findsOneWidget);
  });
}
