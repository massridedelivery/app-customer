import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records the calls instead of hitting the network.
class _SpyAuthController extends AuthController {
  final logins = <(String, String)>[];

  @override
  AuthState build() => const AuthState(isAuthenticated: false);

  @override
  Future<void> login(String email, String password) async {
    logins.add((email, password));
  }
}

Future<_SpyAuthController> _pump(
  WidgetTester tester, {
  LoginMethod method = LoginMethod.phone,
}) async {
  final spy = _SpyAuthController();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => spy)],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => PhoneLoginScreen(initialMethod: method),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  return spy;
}

FilledButton _button(WidgetTester tester, String key) => tester.widget(
  find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(FilledButton),
  ),
);

void main() {
  testWidgets('phone tab: OTP button enables once the number is long enough', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const Key('loginPhone')), findsOneWidget);
    expect(find.byKey(const Key('loginIdentifier')), findsNothing);
    expect(_button(tester, 'loginRequestOtp').onPressed, isNull);

    await tester.enterText(find.byKey(const Key('loginPhone')), '812345678');
    await tester.pump();
    expect(_button(tester, 'loginRequestOtp').onPressed, isNotNull);
  });

  testWidgets('switching to the email tab shows email + password', (
    tester,
  ) async {
    final spy = await _pump(tester);

    await tester.tap(find.text('อีเมล').first);
    await tester.pump();

    expect(find.byKey(const Key('loginPhone')), findsNothing);
    expect(find.byKey(const Key('loginIdentifier')), findsOneWidget);
    expect(find.byKey(const Key('loginPassword')), findsOneWidget);
    expect(_button(tester, 'loginSubmit').onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('loginIdentifier')),
      'me@mass.co',
    );
    await tester.enterText(find.byKey(const Key('loginPassword')), 'secret');
    await tester.pump();
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pump();

    expect(spy.logins, [('me@mass.co', 'secret')]);
  });

  testWidgets('email_login route opens on the email tab', (tester) async {
    await _pump(tester, method: LoginMethod.email);
    expect(find.byKey(const Key('loginIdentifier')), findsOneWidget);
  });

  testWidgets('sign-up link returns to the phone tab', (tester) async {
    await _pump(tester, method: LoginMethod.email);

    await tester.ensureVisible(find.byKey(const Key('loginGoRegister')));
    await tester.tap(find.byKey(const Key('loginGoRegister')));
    await tester.pump();

    expect(find.byKey(const Key('loginPhone')), findsOneWidget);
  });
}
