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
  _SpyAuthController(this.sendResult);

  final EmailOtpSendResult sendResult;
  final emailCodes = <String>[];

  @override
  AuthState build() => const AuthState(isAuthenticated: false);

  @override
  Future<EmailOtpSendResult> sendEmailOtp(String email) async {
    emailCodes.add(email);
    return sendResult;
  }
}

Future<_SpyAuthController> _pump(
  WidgetTester tester, {
  LoginMethod method = LoginMethod.phone,
  Locale locale = const Locale('th'),
  EmailOtpSendResult sendResult = const EmailOtpSendResult.sent(
    refId: 'abcd1234',
    isRegistered: true,
  ),
}) async {
  final spy = _SpyAuthController(sendResult);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => spy)],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => PhoneLoginScreen(initialMethod: method),
            ),
            GoRoute(
              path: '/auth/email-otp',
              builder: (_, state) =>
                  Text('otp:${(state.extra as Map)['email']}'),
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

  testWidgets('email tab sends a code (no password) and opens the OTP page', (
    tester,
  ) async {
    final spy = await _pump(tester);

    await tester.tap(find.text('อีเมล').first);
    await tester.pump();

    expect(find.byKey(const Key('loginPhone')), findsNothing);
    expect(find.byKey(const Key('loginIdentifier')), findsOneWidget);
    expect(find.byKey(const Key('loginPassword')), findsNothing);
    expect(_button(tester, 'loginEmailSend').onPressed, isNull);

    await tester.enterText(find.byKey(const Key('loginIdentifier')), 'me@');
    await tester.pump();
    expect(_button(tester, 'loginEmailSend').onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('loginIdentifier')),
      'me@mass.co',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('loginEmailSend')));
    await tester.pumpAndSettle();

    expect(spy.emailCodes, ['me@mass.co']);
    expect(find.text('otp:me@mass.co'), findsOneWidget);
  });

  testWidgets('email login switched off (503) hides the tabs', (tester) async {
    await _pump(
      tester,
      method: LoginMethod.email,
      sendResult: const EmailOtpSendResult.failed(EmailOtpError.unavailable),
    );

    await tester.enterText(
      find.byKey(const Key('loginIdentifier')),
      'me@mass.co',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('loginEmailSend')));
    await tester.pump();

    expect(find.byKey(const Key('loginMethodTabs')), findsNothing);
    expect(find.byKey(const Key('loginPhone')), findsOneWidget);
    expect(
      find.text('ยังไม่เปิดให้เข้าสู่ระบบด้วยอีเมล กรุณาใช้เบอร์โทรแทน'),
      findsOneWidget,
    );
  });

  testWidgets('email_login route opens on the email tab', (tester) async {
    await _pump(tester, method: LoginMethod.email);
    expect(find.byKey(const Key('loginIdentifier')), findsOneWidget);
  });

  testWidgets('Thai locale shows the Thai tabs, button and heading', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('เบอร์โทร'), findsOneWidget);
    expect(find.text('อีเมล'), findsOneWidget);
    expect(find.text('ขอรหัส OTP'), findsOneWidget);
    expect(find.text('ยินดีต้อนรับ'), findsOneWidget);
    // Phone tab: no sign-up row (a new number signs up via OTP).
    expect(find.text('ยังไม่มีบัญชี?'), findsNothing);
    expect(find.text('สมัครสมาชิก'), findsNothing);

    // Email tab neither: a new email signs up on verify.
    await tester.tap(find.text('อีเมล').first);
    await tester.pump();
    expect(find.text('ยังไม่มีบัญชี?'), findsNothing);
    expect(find.text('ส่งรหัส'), findsOneWidget);
  });

  testWidgets('English locale shows English tabs, button and heading', (
    tester,
  ) async {
    await _pump(tester, locale: const Locale('en'));

    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Request OTP'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsNothing);
    expect(find.textContaining(RegExp('[\u0E00-\u0E7F]')), findsNothing);

    // The email tab's field label and button are English too.
    await tester.tap(find.text('Email'));
    await tester.pump();
    expect(find.text('Email'), findsNWidgets(2)); // tab + field label
    expect(find.text('Send code'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsNothing);
    expect(find.textContaining(RegExp('[\u0E00-\u0E7F]')), findsNothing);
  });
}
