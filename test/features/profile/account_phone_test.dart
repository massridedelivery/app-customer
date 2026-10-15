import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/features/profile/data/account_email.dart';
import 'package:customer_app/features/profile/presentation/screens/account_phone_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Scripted answers + recorded calls shared by every controller instance.
class _Script {
  _Script({
    this.send = const EmailOtpSendResult.sent(refId: 'r7', isRegistered: true),
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
  Future<EmailOtpSendResult> sendAccountPhone(String phone) async {
    script.sent.add(phone);
    return script.send;
  }

  @override
  Future<EmailOtpError?> verifyAccountPhone({
    required String phone,
    required String otp,
    required String refId,
  }) async {
    script.verified.add((phone, otp, refId));
    return script.verifyError;
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Script script, {
  AccountPhone? current,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('profile')),
      ),
      GoRoute(
        path: '/account-phone',
        builder: (_, _) => const AccountPhoneScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (_, state) {
              final extra = state.extra! as Map<String, dynamic>;
              return OtpScreen.linkPhone(
                phone: extra['phone'] as String,
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
        accountPhoneProvider.overrideWith((ref) async => current),
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
  router.push('/account-phone');
  await tester.pumpAndSettle();
}

Future<void> _enterAndSend(WidgetTester tester, String phone) async {
  await tester.enterText(find.byKey(const Key('accountPhoneInput')), phone);
  await tester.pump();
  await tester.tap(find.byKey(const Key('accountPhoneSend')));
  await tester.pumpAndSettle();
}

void main() {
  test('parses GET /auth/phone', () {
    final p = AccountPhone.fromJson({'phone': '+66812345678', 'verified': true});
    expect(p.phone, '+66812345678');
    expect(p.verified, isTrue);
    expect(AccountPhone.fromJson({'phone': ''}).isEmpty, isTrue);
  });

  testWidgets('change number: 08x is sent as E.164, verify returns', (
    tester,
  ) async {
    final script = _Script();
    await _pump(
      tester,
      script,
      current: const AccountPhone(phone: '+66811111111', verified: true),
    );
    expect(find.text('081 111 1111'), findsOneWidget);
    expect(find.text('เปลี่ยนเบอร์'), findsOneWidget);
    expect(find.textContaining('เบอร์เดิมจะถูกแทนที่'), findsOneWidget);

    await _enterAndSend(tester, '0898765432');
    expect(script.sent, ['+66898765432']);
    expect(find.byType(OtpScreen), findsOneWidget);
    // SMS-login fallback polling is off in this mode.
    expect(find.byKey(const Key('smsEmailFallback')), findsNothing);

    await tester.enterText(find.byType(TextField), '246810');
    await tester.pumpAndSettle();
    expect(script.verified, [('+66898765432', '246810', 'r7')]);
    expect(find.text('profile'), findsOneWidget);
    expect(find.text('บันทึกเบอร์แล้ว ใช้เข้าสู่ระบบได้'), findsOneWidget);
  });

  testWidgets('no number yet → "เพิ่มเบอร์โทร"; short input stays disabled', (
    tester,
  ) async {
    await _pump(tester, _Script(), current: const AccountPhone(phone: '', verified: false));
    expect(find.text('เพิ่มเบอร์โทร'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('accountPhoneInput')), '0812');
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('accountPhoneSend')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a number on another account is refused', (tester) async {
    await _pump(
      tester,
      _Script(send: const EmailOtpSendResult.failed(EmailOtpError.phoneInUse)),
    );
    await _enterAndSend(tester, '0812345678');
    expect(find.text('เบอร์นี้ถูกใช้กับบัญชีอื่นแล้ว'), findsOneWidget);
    expect(find.byType(OtpScreen), findsNothing);
  });

  testWidgets('OTP_MISMATCH asks for a new SMS code', (tester) async {
    await _pump(tester, _Script(verifyError: EmailOtpError.mismatch));
    await _enterAndSend(tester, '0812345678');
    await tester.enterText(find.byType(TextField), '111111');
    await tester.pump();
    expect(
      find.text('รหัสนี้ไม่ได้ออกให้เบอร์นี้ กรุณากดส่งรหัสใหม่'),
      findsOneWidget,
    );
  });
}
