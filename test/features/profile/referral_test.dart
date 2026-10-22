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
  int currentUses = 3,
  Map<String, dynamic>? referredBy,
}) => {
  'enabled': enabled,
  'referral_code': {
    'code': 'AB12CD34',
    'max_uses': 50,
    'current_uses': currentUses,
  },
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

// The current GET /api/customer/loyalty/referral shape.
Map<String, dynamic> _newJson() => {
  'enabled': true,
  'referral_code': {
    'code': 'K7QM2X',
    'max_uses': 50,
    'current_uses': 3,
    'is_active': true,
  },
  'referrer_points': 100,
  'referee_discount_baht': 50,
  'share_message': 'ใช้โค้ด K7QM2X ลด ฿50 เรียกรถครั้งแรกกับ Mass Move',
  'stats': {'invited': 3, 'completed': 1, 'points_earned': 100},
  'friends': [
    {
      'name': 'สมชาย ใ.',
      'status': 'REWARDED',
      'points': 100,
      'created_at': '2026-10-20T08:00:00Z',
      'rewarded_at': '2026-10-21T10:00:00Z',
    },
    {
      'name': 'Nok K.',
      'status': 'PENDING',
      'points': 100,
      'created_at': '2026-10-22T07:00:00Z',
      'rewarded_at': null,
    },
    {
      'name': 'Joe P.',
      'status': 'CANCELLED',
      'points': 100,
      'created_at': '2026-10-19T07:00:00Z',
      'rewarded_at': null,
    },
  ],
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

  testWidgets('shows the code and the numbers from the API', (tester) async {
    await _pump(tester, ReferralInfo.fromJson(_json()));
    expect(find.text('AB12CD34'), findsOneWidget);
    expect(find.text('เพื่อนได้ ฿50 · คุณได้ 500 คะแนน'), findsOneWidget);
    expect(find.text('1,500'), findsOneWidget);
    expect(
      find.text('ชวนแล้ว 4 · สำเร็จ 3 · ได้ 1,500 คะแนน'),
      findsOneWidget,
    );
    expect(find.text('แชร์โค้ดให้เพื่อน'), findsOneWidget);
    expect(find.byKey(const Key('referralCodeFull')), findsNothing);
    expect(find.byKey(const Key('referralReferredBy')), findsNothing);
  });

  test('parses the new contract (referrer_points, friends, share_message)', () {
    final info = ReferralInfo.fromJson(_newJson());
    expect(info.code, 'K7QM2X');
    expect(info.referrerRewardPoints, 100);
    expect(info.friendRewardValue, 50);
    expect(info.shareMessage, startsWith('ใช้โค้ด K7QM2X'));
    expect(info.stats.totalReferrals, 3);
    expect(info.stats.completedCount, 1);
    expect(info.stats.totalRewardPoints, 100);
    expect(info.friends.map((f) => f.status), [
      'REWARDED',
      'PENDING',
      'CANCELLED',
    ]);
    expect(info.friends.first.rewardedAt, isNotNull);
  });

  testWidgets('friends list shows each status', (tester) async {
    await _pump(tester, ReferralInfo.fromJson(_newJson()));
    expect(find.text('เพื่อนได้ ฿50 · คุณได้ 100 คะแนน'), findsOneWidget);
    expect(find.text('สมชาย ใ.'), findsOneWidget);
    expect(find.text('ได้ 100 คะแนน'), findsOneWidget);
    expect(find.text('รอเดินทางครั้งแรก'), findsOneWidget);
    expect(find.byKey(const Key('referralFriend-CANCELLED')), findsOneWidget);
  });

  testWidgets('already referred → reminder while PENDING', (tester) async {
    await _pump(
      tester,
      ReferralInfo.fromJson(
        _json(
          canApply: true,
          referredBy: {
            'code': '3F2AK7QX',
            'status': 'PENDING',
            'welcome_promo': {'code': 'FRIEND50', 'discount_value': 50},
          },
        ),
      ),
    );
    expect(find.text('คุณสมัครด้วยรหัส 3F2AK7QX'), findsOneWidget);
    expect(
      find.text('อย่าลืมใช้โค้ด FRIEND50 ในออเดอร์แรก ลด ฿50'),
      findsOneWidget,
    );
  });

  test('codeFull only once current_uses reaches max_uses', () {
    expect(ReferralInfo.fromJson(_json()).codeFull, isFalse);
    expect(ReferralInfo.fromJson(_json(currentUses: 50)).codeFull, isTrue);
  });

  testWidgets('a code with every friend slot used says so', (tester) async {
    await _pump(tester, ReferralInfo.fromJson(_json(currentUses: 50)));
    expect(find.text('รหัสนี้ชวนเพื่อนครบจำนวนแล้ว'), findsOneWidget);
  });

  testWidgets('programme switched off', (tester) async {
    await _pump(tester, ReferralInfo.fromJson(_json(enabled: false)));
    expect(find.text('ขณะนี้ยังไม่เปิดโปรแกรมชวนเพื่อน'), findsOneWidget);
    expect(find.text('AB12CD34'), findsNothing);
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
