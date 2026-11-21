import 'package:customer_app/features/profile/domain/models/referral_info.dart';
import 'package:customer_app/features/profile/presentation/screens/referral_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// GET /api/customer/loyalty/referral with the coupon milestones
// (backend internal/loyalty/referral TierProgress: friends, amount, reached,
// voucher_code; friends_counted).
Map<String, dynamic> _json({Object? tiers, Object? counted}) => {
  'enabled': true,
  'referral_code': {'code': 'K7QM2X', 'max_uses': 50, 'current_uses': 3},
  'referrer_points': 100,
  'referee_discount_baht': 50,
  'stats': {'invited': 4, 'completed': 3, 'points_earned': 300},
  'tiers': ?tiers,
  'friends_counted': ?counted,
};

const _tiers = [
  {'friends': 1, 'amount': 20, 'reached': true, 'voucher_code': 'RT-AB12'},
  {'friends': 5, 'amount': 75, 'reached': false},
  {'friends': 10, 'amount': 150, 'reached': false},
];

Future<void> _pump(WidgetTester tester, ReferralInfo info) async {
  tester.view.physicalSize = const Size(1080, 3600);
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
  test('parses tiers and friends_counted', () {
    final info = ReferralInfo.fromJson(_json(tiers: _tiers, counted: 3));
    expect(info.tiers.map((t) => t.friends), [1, 5, 10]);
    expect(info.tiers.first.reached, isTrue);
    expect(info.tiers.first.voucherCode, 'RT-AB12');
    expect(info.tiers[1].voucherCode, isNull);
    expect(info.tiers[1].amount, 75);
    expect(info.friendsCounted, 3);
    expect(info.nextTier!.friends, 5);
    expect(info.friendsToNextTier, 2);
  });

  test('missing, empty or malformed tiers mean none', () {
    for (final t in [
      null,
      const [],
      'x',
      const [{}],
    ]) {
      final info = ReferralInfo.fromJson(_json(tiers: t));
      expect(info.tiers, isEmpty, reason: '$t');
      expect(info.nextTier, isNull);
      expect(info.friendsToNextTier, 0);
    }
    expect(ReferralInfo.fromJson(_json()).friendsCounted, 0);
  });

  test('every tier reached: no next goal', () {
    final info = ReferralInfo.fromJson(
      _json(
        tiers: [
          {'friends': 1, 'amount': 20, 'reached': true, 'voucher_code': 'A'},
        ],
        counted: 4,
      ),
    );
    expect(info.nextTier, isNull);
  });

  testWidgets('track: next goal, stops and the earned coupon', (tester) async {
    await _pump(
      tester,
      ReferralInfo.fromJson(_json(tiers: _tiers, counted: 3)),
    );
    expect(find.text('ชวนอีก 2 คน รับคูปอง ฿75'), findsOneWidget);
    expect(find.byKey(const Key('referralTier-10')), findsOneWidget);
    expect(find.byKey(const Key('referralTierEarned-1')), findsOneWidget);
    expect(find.byKey(const Key('referralTierEarned-5')), findsNothing);
    expect(find.text('RT-AB12'), findsOneWidget);
    expect(find.byKey(const Key('referralTiersVouchers')), findsOneWidget);
  });

  testWidgets('no tiers → no track', (tester) async {
    await _pump(tester, ReferralInfo.fromJson(_json()));
    expect(find.byKey(const Key('referralTiers')), findsNothing);
  });
}
