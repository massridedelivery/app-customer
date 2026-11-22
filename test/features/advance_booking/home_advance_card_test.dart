import 'package:customer_app/features/advance_booking/domain/advance_config.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_common.dart';
import 'package:customer_app/features/advance_booking/presentation/home_advance_card.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth extends AuthController {
  _Auth(this.signedIn);
  final bool signedIn;
  @override
  AuthState build() => AuthState(isAuthenticated: signedIn);
}

ProviderContainer _container({
  required bool signedIn,
  required Future<AdvanceConfig> Function() config,
}) {
  final c = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => _Auth(signedIn)),
      advanceConfigProvider.overrideWith((ref) => config()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _settle(ProviderContainer c) async {
  c.listen(homeAdvanceCardVisibleProvider, (_, _) {});
  c.listen(advanceConfigProvider, (_, _) {});
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('homeAdvanceCardVisibleProvider', () {
    test('a guest always sees the card', () async {
      final c = _container(
        signedIn: false,
        config: () => Future.error(Exception('404')),
      );
      await _settle(c);
      expect(c.read(homeAdvanceCardVisibleProvider), isTrue);
    });

    test('hidden when the config cannot load (backend without it)', () async {
      final c = _container(
        signedIn: true,
        config: () => Future.error(Exception('404')),
      );
      await _settle(c);
      expect(c.read(homeAdvanceCardVisibleProvider), isFalse);
    });

    test(
      'shown once the config loads, even with advance booking off',
      () async {
        final c = _container(
          signedIn: true,
          config: () async => AdvanceConfig.fromJson(const {'enabled': false}),
        );
        await _settle(c);
        expect(c.read(homeAdvanceCardVisibleProvider), isTrue);
      },
    );
  });

  testWidgets('the card reads like the other service cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => _Auth(false))],
        child: const MaterialApp(
          locale: Locale('th'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 150,
              child: HomeAdvanceBookingCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('จองล่วงหน้า'), findsOneWidget);
    expect(find.text('นัดรถล่วงหน้า'), findsOneWidget);
    expect(find.text('ใหม่'), findsOneWidget);
    expect(find.byType(AdvanceCalendarArt), findsOneWidget);
    expect(find.byKey(const Key('homeAdvanceBookingCard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
