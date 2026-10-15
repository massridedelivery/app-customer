import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/features/profile/data/account_email.dart';
import 'package:customer_app/features/profile/presentation/screens/account_email_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Scripted answers + recorded calls, shared by every controller instance
/// (Riverpod builds a fresh one each time the provider is re-created).
class _Script {
  _Script({
    this.send = const EmailOtpSendResult.sent(refId: 'ref9', isRegistered: true),
    this.verifyError,
  });

  final EmailOtpSendResult send;
  final EmailOtpError? verifyError;
  final sent = <String>[];
  final verified = <(String, String, String)>[];
}

class _FakeAuth extends AuthController {
  _FakeAuth(this.script);

  final _Script script;

  @override
  AuthState build() => const AuthState(isAuthenticated: true);

  @override
  Future<EmailOtpSendResult> sendAccountEmail(String email) async {
    script.sent.add(email);
    return script.send;
  }

  @override
  Future<EmailOtpError?> verifyAccountEmail({
    required String email,
    required String otp,
    required String refId,
  }) async {
    script.verified.add((email, otp, refId));
    return script.verifyError;
  }
}

/// Profile stub at `/` that opens the email screen, so pops have somewhere
/// to land.
Future<void> _pump(
  WidgetTester tester,
  _Script script, {
  AccountEmail? current,
  String start = '/account-email',
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('profile')),
      ),
      GoRoute(
        path: '/account-email',
        builder: (_, _) => const AccountEmailScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (_, state) {
              final extra = state.extra! as Map<String, dynamic>;
              return OtpScreen.linkEmail(
                email: extra['email'] as String,
                refId: extra['refId'] as String,
              );
            },
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(script)),
        accountEmailProvider.overrideWith((ref) async => current),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  router.push(start);
  await tester.pumpAndSettle();
}

void main() {
  test('parses GET /auth/email', () {
    final e = AccountEmail.fromJson({'email': 'a@x.com', 'verified': true});
    expect(e.email, 'a@x.com');
    expect(e.verified, isTrue);
    expect(AccountEmail.fromJson({'email': '', 'verified': false}).isEmpty,
        isTrue);
  });

  testWidgets('verified email: badge, sign-in note, change flow', (
    tester,
  ) async {
    await _pump(
      tester,
      _Script(),
      current: const AccountEmail(email: 'a@x.com', verified: true),
    );
    expect(find.text('a@x.com'), findsOneWidget);
    expect(find.text('ยืนยันแล้ว'), findsOneWidget);
    expect(find.text('ใช้เข้าสู่ระบบได้'), findsOneWidget);
    expect(find.text('เปลี่ยนอีเมล'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('accountEmailInput')),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('unverified email is pre-filled; code verifies and returns', (
    tester,
  ) async {
    final fake = _Script();
    await _pump(
      tester,
      fake,
      current: const AccountEmail(email: 'b@x.com', verified: false),
    );
    expect(find.text('ยังไม่ยืนยัน'), findsOneWidget);

    await tester.tap(find.byKey(const Key('accountEmailSend')));
    await tester.pumpAndSettle();
    expect(fake.sent, ['b@x.com']);
    expect(find.byType(OtpScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), '654321');
    await tester.pumpAndSettle();
    expect(fake.verified, [('b@x.com', '654321', 'ref9')]);
    // Back on the profile, with the success message.
    expect(find.text('profile'), findsOneWidget);
    expect(find.text('ยืนยันอีเมลแล้ว ใช้เข้าสู่ระบบได้'), findsOneWidget);
  });

  testWidgets('an email owned by another account is refused', (tester) async {
    await _pump(
      tester,
      _Script(send: const EmailOtpSendResult.failed(EmailOtpError.emailInUse)),
    );
    await tester.enterText(
      find.byKey(const Key('accountEmailInput')),
      'taken@x.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('accountEmailSend')));
    await tester.pump();
    expect(find.text('อีเมลนี้ถูกใช้กับบัญชีอื่นแล้ว'), findsOneWidget);
    expect(find.byType(OtpScreen), findsNothing);
  });

  testWidgets('OTP_MISMATCH asks for a new code', (tester) async {
    await _pump(
      tester,
      _Script(verifyError: EmailOtpError.mismatch),
      current: const AccountEmail(email: 'b@x.com', verified: false),
    );
    await tester.tap(find.byKey(const Key('accountEmailSend')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '111111');
    await tester.pump();
    expect(
      find.text('รหัสนี้ไม่ได้ออกให้อีเมลนี้ กรุณากดส่งรหัสใหม่'),
      findsOneWidget,
    );
    expect(find.byType(OtpScreen), findsOneWidget);
  });
}
