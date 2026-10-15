import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Answers the email-OTP calls instead of hitting the network.
class _FakeAuthController extends AuthController {
  _FakeAuthController({this.verifyError, this.fallbackOffered = false});

  final EmailOtpError? verifyError;
  final bool fallbackOffered;
  final verified = <(String, String, String)>[];

  @override
  AuthState build() => const AuthState(isAuthenticated: false);

  @override
  Future<EmailOtpError?> verifyEmailOtp({
    required String email,
    required String otp,
    required String refId,
  }) async {
    verified.add((email, otp, refId));
    return verifyError;
  }

  @override
  Future<bool> smsEmailFallbackOffered(String refId) async => fallbackOffered;
}

Future<void> _pump(
  WidgetTester tester,
  _FakeAuthController fake,
  Widget screen,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => fake)],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => screen),
            GoRoute(
              path: '/auth/email_login',
              builder: (_, _) => const Text('email login'),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('email mode: masked email, ref and new-account warning', (
    tester,
  ) async {
    final fake = _FakeAuthController();
    await _pump(
      tester,
      fake,
      const OtpScreen.email(
        email: 'somchai@gmail.com',
        refId: 'x9f2a1b7',
        isRegistered: false,
      ),
    );

    expect(
      find.text('ส่งรหัสไปที่ s***@gmail.com แล้ว · รหัสอ้างอิง a1b7'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('emailNewAccountWarning')), findsOneWidget);
    expect(find.byKey(const Key('smsEmailFallback')), findsNothing);
  });

  testWidgets('email mode: a wrong code shows the error and clears the field', (
    tester,
  ) async {
    final fake = _FakeAuthController(verifyError: EmailOtpError.invalidOtp);
    await _pump(
      tester,
      fake,
      const OtpScreen.email(
        email: 'me@mass.co',
        refId: 'ref1',
        isRegistered: true,
      ),
    );
    expect(find.byKey(const Key('emailNewAccountWarning')), findsNothing);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    expect(fake.verified, [('me@mass.co', '123456', 'ref1')]);
    expect(find.text('รหัสไม่ถูกต้อง'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('SMS mode offers email once the backend flags the fallback', (
    tester,
  ) async {
    final fake = _FakeAuthController(fallbackOffered: true);
    await _pump(
      tester,
      fake,
      const OtpScreen(phone: '+66812345678', refId: 'r', isRegistered: true),
    );
    expect(find.byKey(const Key('smsEmailFallback')), findsNothing);

    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    expect(find.text('ไม่ได้รับ SMS? รับรหัสทางอีเมลแทน'), findsOneWidget);

    await tester.tap(find.byKey(const Key('smsEmailFallback')));
    await tester.pumpAndSettle();
    expect(find.text('email login'), findsOneWidget);
  });
}
