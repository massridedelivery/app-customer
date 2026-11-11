import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/features/auth/data/models/send_otp_response.dart';
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

  /// SMS resend: answers with [resendResult] (default: a new ref id).
  PhoneOtpSendResult? resendResult;
  final resent = <String>[];

  @override
  Future<PhoneOtpSendResult> sendOtp(String phone) async {
    resent.add(phone);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return resendResult ??
        PhoneOtpSendResult.sent(
          SendOtpResponse(message: 'ok', refId: 'ref-new', isRegistered: true),
        );
  }

  final smsVerified = <(String, String)>[];

  @override
  Future<bool> sendVerifyOtp({
    required String phone,
    required String otp,
    required String refId,
    required String role,
    required bool isRegistered,
    String? fullName,
  }) async {
    smsVerified.add((otp, refId));
    return false;
  }
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

  testWidgets('SMS resend: one send per tap, verify uses the new ref_id', (
    tester,
  ) async {
    final fake = _FakeAuthController();
    await _pump(
      tester,
      fake,
      const OtpScreen(
        phone: '+66892616445',
        refId: 'ref-old',
        isRegistered: true,
      ),
    );
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();

    await tester.tap(find.byKey(const Key('otpResend')));
    await tester.pump(); // in flight: the link is off
    await tester.tap(find.byKey(const Key('otpResend')), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(fake.resent, ['+66892616445']);
    expect(find.text('ส่งรหัสอีกครั้งใน 01:00'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '654321');
    await tester.pump();
    expect(fake.smsVerified, [('654321', 'ref-new')]);
    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('SMS resend 429: shows why and counts down retry_after', (
    tester,
  ) async {
    final fake = _FakeAuthController()
      ..resendResult = const PhoneOtpSendResult.failed(
        OtpSendError.rateLimited,
        'ขอ OTP บ่อยเกินไป',
        retryAfter: 90,
      );
    await _pump(
      tester,
      fake,
      const OtpScreen(
        phone: '+66892616445',
        refId: 'ref-old',
        isRegistered: true,
      ),
    );
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();

    await tester.tap(find.byKey(const Key('otpResend')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ขอ OTP บ่อยเกินไป'), findsOneWidget);
    expect(find.text('ส่งรหัสอีกครั้งใน 01:30'), findsOneWidget);
    expect(find.byKey(const Key('otpResend')), findsNothing);

    // The old code still verifies against the old ref.
    await tester.enterText(find.byType(TextField), '111111');
    await tester.pump();
    expect(fake.smsVerified, [('111111', 'ref-old')]);
    await tester.pump(const Duration(seconds: 91));
  });

  testWidgets('SMS resend failure (500) shows the message, can try again', (
    tester,
  ) async {
    final fake = _FakeAuthController()
      ..resendResult = const PhoneOtpSendResult.failed(
        OtpSendError.sendFailed,
        'ส่ง OTP ไม่สำเร็จ ลองใหม่อีกครั้ง',
      );
    await _pump(
      tester,
      fake,
      const OtpScreen(phone: '+66892616445', refId: 'r', isRegistered: true),
    );
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    await tester.tap(find.byKey(const Key('otpResend')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ส่ง OTP ไม่สำเร็จ ลองใหม่อีกครั้ง'), findsOneWidget);
    expect(find.byKey(const Key('otpResend')), findsOneWidget);
  });
}
