import 'package:customer_app/features/profile/data/welcome_promo_store.dart';
import 'package:customer_app/features/profile/domain/models/referral_info.dart';
import 'package:customer_app/features/profile/presentation/screens/referral_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The BE #194 sample payload.
Map<String, dynamic> _json({
  bool enabled = true,
  bool canApply = false,
  Map<String, dynamic>? referredBy,
}) => {
  'enabled': enabled,
  'referral_code': {'code': 'AB12CD34', 'max_uses': 50, 'current_uses': 3},
  'referrer_reward_points': 500,
  'friend_reward': {
    'code': 'FRIEND50',
    'name': 'Friend welcome',
    'discount_type': 'fixed',
    'discount_value': 50,
    'max_discount': null,
    'valid_until': '2026-12-31T16:59:59Z',
  },
  'stats': {
    'total_referrals': 4,
    'completed_count': 3,
    'pending_count': 1,
    'total_reward_points': 1500,
    'pending_reward_points': 500,
  },
  'can_apply_code': canApply,
  'apply_before': canApply ? '2026-10-20T10:00:00Z' : null,
  'referred_by': referredBy,
};

Future<void> _pump(WidgetTester tester, ReferralInfo info) async {
  // A phone-sized tall viewport so the whole (lazy) list is built.
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [referralInfoProvider.overrideWith((ref) async => info)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('th'),
        home: ReferralScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('parses the BE payload', () {
    final info = ReferralInfo.fromJson(_json());
    expect(info.enabled, isTrue);
    expect(info.code, 'AB12CD34');
    expect(info.referrerRewardPoints, 500);
    expect(info.friendRewardCode, 'FRIEND50');
    expect(info.friendRewardValue, 50);
    expect(info.stats.totalReferrals, 4);
    expect(info.stats.pendingRewardPoints, 500);
    expect(info.wasReferred, isFalse);
  });

  test('a PENDING referral exposes the welcome code to use', () {
    final info = ReferralInfo.fromJson(
      _json(
        referredBy: {
          'status': 'PENDING',
          'welcome_promo': {'code': 'FRIEND50'},
        },
      ),
    );
    expect(info.wasReferred, isTrue);
    expect(info.welcomePromoPending, isTrue);
    expect(info.referredByWelcomeCode, 'FRIEND50');
  });

  testWidgets('shows the code, numbers from the API and pending friends', (
    tester,
  ) async {
    await _pump(tester, ReferralInfo.fromJson(_json()));
    expect(find.text('AB12CD34'), findsOneWidget);
    expect(
      find.text('เพื่อนได้ส่วนลด ฿50 · คุณรับ 500 แต้มเมื่อเพื่อนใช้บริการครั้งแรก'),
      findsOneWidget,
    );
    expect(find.text('1500'), findsOneWidget);
    expect(find.text('รอเพื่อนใช้บริการ 1 คน (500 แต้ม)'), findsOneWidget);
    // Not a new customer → no apply card.
    expect(find.byKey(const Key('referralApplyCard')), findsNothing);
  });

  testWidgets('a new customer can enter a code (with its deadline)', (
    tester,
  ) async {
    await _pump(tester, ReferralInfo.fromJson(_json(canApply: true)));
    expect(find.byKey(const Key('referralApplyCard')), findsOneWidget);
    expect(find.textContaining('กรอกได้ถึง'), findsOneWidget);
  });

  testWidgets('already referred → no apply card, reminder while PENDING', (
    tester,
  ) async {
    await _pump(
      tester,
      ReferralInfo.fromJson(
        _json(
          canApply: true,
          referredBy: {
            'status': 'PENDING',
            'welcome_promo': {'code': 'FRIEND50'},
          },
        ),
      ),
    );
    expect(find.byKey(const Key('referralApplyCard')), findsNothing);
    expect(find.text('อย่าลืมใช้โค้ด FRIEND50 ในออเดอร์แรก'), findsOneWidget);
  });

  testWidgets('programme switched off', (tester) async {
    await _pump(tester, ReferralInfo.fromJson(_json(enabled: false)));
    expect(find.text('ขณะนี้ยังไม่เปิดให้ใช้รหัสแนะนำ'), findsOneWidget);
    expect(find.text('AB12CD34'), findsNothing);
  });

  test('apply error codes map to messages', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('th'));
    expect(referralApplyError(l10n, 'referral_self'), 'ใช้รหัสของตัวเองไม่ได้');
    expect(
      referralApplyError(l10n, 'referral_window_closed'),
      'เลยเวลากรอกรหัสแนะนำแล้ว',
    );
    expect(referralApplyError(l10n, 'referral_code_full'), 'รหัสนี้ถูกใช้ครบจำนวนแล้ว');
    expect(referralApplyError(l10n, 'something_new'), l10n.profileReferralApplyInvalid);
  });

  test('welcome code is cleared only when that code was used', () async {
    SharedPreferences.setMockInitialValues({});
    final store = WelcomePromoStore(await SharedPreferences.getInstance());
    await store.save('FRIEND50');
    await store.consume('DIS50');
    expect(store.code, 'FRIEND50');
    await store.consume('friend50');
    expect(store.code, isNull);
  });
}
