import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/features/profile/data/datasources/loyalty_remote_data_source.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/profile/presentation/screens/loyalty_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/loyalty_tiers_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/rewards_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/vouchers_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Map<String, dynamic> _reward(
  String id, {
  int cost = 80,
  bool can = true,
  String? reason,
  int? stock = 57,
  String? startsAt,
}) => {
  'id': id,
  'title': 'Reward $id',
  'description': 'desc',
  'terms': 'ใช้ได้ 1 ครั้ง\nไม่สามารถแลกเป็นเงินสดได้',
  'image_url': null,
  'points_cost': cost,
  'discount_text': 'ลด ฿30 ค่าเรียกรถ',
  'applies_to': 'RIDE',
  'stock_left': stock,
  'can_redeem': can,
  'reason': reason,
  'starts_at': startsAt,
  'ends_at': '2026-12-31T16:59:59Z',
};

Map<String, dynamic> _voucher(String code, {String status = 'ACTIVE'}) => {
  'id': 'v-$code',
  'code': code,
  'title': 'ส่วนลดค่าเรียกรถ 30 บาท',
  'discount_text': 'ลด ฿30 ค่าเรียกรถ',
  'applies_to': 'RIDE',
  'points_spent': 80,
  'status': status,
  'expires_at': DateTime.now()
      .add(const Duration(days: 1))
      .toUtc()
      .toIso8601String(),
  'used_at': status == 'USED' ? '2026-10-23T02:10:44Z' : null,
  'used_order_type': status == 'USED' ? 'RIDE' : null,
};

/// Serves fixed JSON; redeem can fail with a dropped connection first.
class _FakeLoyalty implements LoyaltyRemoteDataSource {
  _FakeLoyalty({
    this.rewards = const [],
    this.failFirstRedeem = false,
    this.failFirstRedeemWith500 = false,
    this.spending,
    this.tier,
  });

  final List<Map<String, dynamic>> rewards;
  final Map<String, dynamic>? spending;
  final Map<String, dynamic>? tier;
  bool failFirstRedeem;
  bool failFirstRedeemWith500;
  final redeemKeys = <String>[];

  @override
  Future<Map<String, dynamic>> getSummary() async => {
    'points': {'total_points': 1250, 'lifetime_points': 1400},
    'points_enabled': true,
    'points_baht_value': 1,
    'balance_baht': 1250,
    'expiring_soon': {'points': 120, 'expires_at': '2026-11-10T03:12:00Z'},
    'earn_per_100_baht': {'ride': 1, 'min_order': 50},
    'spending': ?spending,
    'tier': ?tier,
  };

  @override
  Future<Map<String, dynamic>> getTiers() async => {
    'tiers': [
      {
        'code': 'SILVER',
        'name': 'Silver',
        'name_th': 'ซิลเวอร์',
        'name_en': 'Silver',
        'color': '#9AA0A6',
        'min_points': 0,
        'max_points': 999,
        'earn_multiplier': 1,
        'benefits_th': ['สะสมคะแนนทุกการเดินทาง'],
      },
      {
        'code': 'GOLD',
        'name': 'Gold',
        'name_th': 'โกลด์',
        'name_en': 'Gold',
        'color': '#C9A227',
        'min_points': 1000,
        'max_points': null,
        'earn_multiplier': 1.5,
        'benefits_th': ['ได้คะแนนเพิ่ม 50%', 'คูปองวันเกิด'],
      },
    ],
  };

  @override
  Future<Map<String, dynamic>> getPoints({
    int limit = 20,
    int offset = 0,
  }) async => {
    'transactions': offset > 0
        ? <Map<String, dynamic>>[]
        : [
            {
              'id': '1',
              'type': 'EARN',
              'points': 100,
              'order_type': 'REFERRAL',
              'created_at': '2026-10-21T10:00:00Z',
            },
            {
              'id': '2',
              'type': 'REDEEM',
              'points': -80,
              'created_at': '2026-10-21T11:00:00Z',
            },
            {
              'id': '3',
              'type': 'REDEEM',
              'points': -30,
              'order_type': 'RIDE',
              'created_at': '2026-10-21T12:00:00Z',
            },
            {
              'id': '4',
              'type': 'REFUND',
              'points': 30,
              'order_type': 'RIDE',
              'created_at': '2026-10-21T13:00:00Z',
            },
          ],
  };

  @override
  Future<Map<String, dynamic>> getRewards() async => {
    'points_enabled': true,
    'points_balance': 120,
    'items': rewards,
  };

  @override
  Future<Map<String, dynamic>> redeemReward(
    String id, {
    required String idempotencyKey,
  }) async {
    redeemKeys.add(idempotencyKey);
    if (failFirstRedeem) {
      failFirstRedeem = false;
      throw DioException(
        requestOptions: RequestOptions(path: '/redeem'),
        type: DioExceptionType.connectionError,
      );
    }
    if (failFirstRedeemWith500) {
      failFirstRedeemWith500 = false;
      throw DioException(
        requestOptions: RequestOptions(path: '/redeem'),
        response: Response(
          requestOptions: RequestOptions(path: '/redeem'),
          statusCode: 500,
          data: {'code': 'DB_TIMEOUT', 'error': 'ระบบขัดข้อง ลองใหม่อีกครั้ง'},
        ),
      );
    }
    return {
      'voucher': _voucher('RW-7KQ2-M9XD'),
      'points_spent': 80,
      'points_balance': 40,
      'replayed': redeemKeys.length > 1,
    };
  }

  @override
  Future<Map<String, dynamic>> getVouchers({String status = 'ACTIVE'}) async =>
      {
        'items': status == 'ACTIVE'
            ? [_voucher('RW-AAAA-BBBB')]
            : status == 'USED'
            ? [_voucher('RW-USED-0001', status: 'USED')]
            : status == 'VOIDED'
            ? [_voucher('RW-VOID-0001', status: 'VOIDED')]
            : <Map<String, dynamic>>[],
      };
}

Future<void> _pump(
  WidgetTester tester,
  _FakeLoyalty fake, {
  String initial = '/rewards',
}) async {
  tester.view.physicalSize = const Size(1080, 2800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/loyalty',
        builder: (_, _) => const LoyaltyScreen(),
        routes: [
          GoRoute(path: 'tiers', builder: (_, _) => const LoyaltyTiersScreen()),
        ],
      ),
      GoRoute(path: '/vouchers', builder: (_, _) => const VouchersScreen()),
      GoRoute(
        path: '/rewards',
        builder: (_, _) => const RewardsScreen(),
        routes: [
          GoRoute(
            path: 'success',
            builder: (_, state) =>
                RedeemSuccessScreen(result: state.extra! as RedeemResult),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [loyaltyRemoteDataSourceProvider.overrideWithValue(fake)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('models', () {
    test('summary, reward, voucher, redeem result', () {
      final r = Reward.fromJson(_reward('a', stock: null));
      expect(r.stockLeft, isNull);
      expect(r.terms.split('\n'), hasLength(2));
      final res = RedeemResult.fromJson({
        'voucher': _voucher('RW-1'),
        'points_balance': 40,
        'replayed': true,
      });
      expect(res.voucher.code, 'RW-1');
      expect(res.pointsBalance, 40);
      expect(res.replayed, isTrue);
    });

    test('ApiError keeps the server text and extras', () {
      final e = ApiError.from(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 409,
            data: {
              'code': 'POINTS_INSUFFICIENT',
              'error': 'คะแนนไม่พอ คุณมี 30 คะแนน',
              'balance': 30,
              'max_usable_points': 30,
            },
          ),
        ),
      );
      expect(e.code, 'POINTS_INSUFFICIENT');
      expect(e.message, 'คะแนนไม่พอ คุณมี 30 คะแนน');
      expect(e.intExtra('max_usable_points'), 30);
      expect(e.isNetwork, isFalse);
    });
  });

  testWidgets('redeem buttons follow the reason', (tester) async {
    await _pump(
      tester,
      _FakeLoyalty(
        rewards: [
          _reward('ok'),
          _reward('poor', cost: 200, can: false, reason: 'INSUFFICIENT_POINTS'),
          _reward('gone', can: false, reason: 'OUT_OF_STOCK', stock: 0),
          _reward('max', can: false, reason: 'LIMIT_REACHED'),
        ],
      ),
    );
    expect(find.text('คุณมี 120 คะแนน'), findsOneWidget);
    expect(find.text('ขาดอีก 80 คะแนน'), findsOneWidget);
    expect(find.text('แลกหมดแล้ว'), findsOneWidget);
    expect(find.text('แลกครบสิทธิ์แล้ว'), findsOneWidget);
    expect(find.text('เหลือ 0'), findsOneWidget);
    final ok = tester.widget<FilledButton>(
      find.byKey(const Key('rewardRedeem-ok')),
    );
    final poor = tester.widget<FilledButton>(
      find.byKey(const Key('rewardRedeem-poor')),
    );
    expect(ok.onPressed, isNotNull);
    expect(poor.onPressed, isNull);
  });

  testWidgets('a dropped redeem retries with the same Idempotency-Key', (
    tester,
  ) async {
    final fake = _FakeLoyalty(rewards: [_reward('ok')], failFirstRedeem: true);
    await _pump(tester, fake);
    await tester.tap(find.byKey(const Key('rewardRedeem-ok')));
    await tester.pumpAndSettle();
    expect(find.text('ใช้ 80 คะแนน แลก ลด ฿30 ค่าเรียกรถ?'), findsOneWidget);
    expect(find.text('คะแนนคงเหลือ 40'), findsOneWidget);

    await tester.tap(find.byKey(const Key('redeemConfirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('redeemError')), findsOneWidget);

    await tester.tap(find.byKey(const Key('redeemConfirm')));
    await tester.pumpAndSettle();
    expect(fake.redeemKeys, hasLength(2));
    expect(fake.redeemKeys.toSet(), hasLength(1));
    // Success screen with the voucher and the new balance.
    expect(find.text('แลกสำเร็จ'), findsOneWidget);
    expect(find.text('RW-7KQ2-M9XD'), findsOneWidget);
    expect(find.text('คุณมี 40 คะแนน'), findsOneWidget);
  });

  testWidgets('my points: balance, expiry warning and Thai history labels', (
    tester,
  ) async {
    await _pump(tester, _FakeLoyalty(), initial: '/loyalty');
    expect(find.text('1,250'), findsOneWidget);
    expect(find.text('มูลค่า ≈ ฿1,250'), findsOneWidget);
    expect(find.byKey(const Key('pointsExpiring')), findsOneWidget);
    expect(
      find.text('รับ 1 คะแนนทุก ฿100 ที่จ่าย (ขั้นต่ำ ฿50)'),
      findsOneWidget,
    );
    expect(find.text('ชวนเพื่อนสำเร็จ'), findsOneWidget);
    expect(find.text('แลกคูปอง'), findsOneWidget);
    expect(find.text('ใช้คะแนน'), findsOneWidget);
    expect(find.text('คืนคะแนน'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.text('−80'), findsOneWidget);
  });

  testWidgets('my vouchers: tabs, expiring soon in red, used info', (
    tester,
  ) async {
    await _pump(tester, _FakeLoyalty(), initial: '/vouchers');
    expect(find.text('RW-AAAA-BBBB'), findsOneWidget);
    // Expires within a day: the ticket says how long is left.
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('voucher-RW-AAAA-BBBB')),
              matching: find.byKey(const Key('couponMeta')),
            ),
          )
          .textSpan!
          .toPlainText(),
      contains('เหลือ'),
    );
    expect(find.byKey(const Key('voucherUse-RW-AAAA-BBBB')), findsOneWidget);

    await tester.tap(find.text('ใช้แล้ว'));
    await tester.pumpAndSettle();
    expect(find.text('RW-USED-0001'), findsOneWidget);
    expect(find.textContaining('· เรียกรถ'), findsOneWidget);

    await tester.tap(find.text('หมดอายุ'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vouchersEmpty')), findsOneWidget);
  });

  test('pending "ใช้เลย" code is handed to its service once', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final pending = container.read(pendingPromoCodeProvider.notifier);
    pending.set('RW-AAAA-BBBB', 'RIDE');
    expect(pending.take('MESSENGER'), isNull);
    expect(pending.take('RIDE'), 'RW-AAAA-BBBB');
    expect(pending.take('RIDE'), isNull);
  });

  group('spending (ใช้บริการไปแล้ว)', () {
    const sample = {
      'total_baht': 408,
      'orders': 3,
      'points_earned': 3,
      'ride': {'baht': 120, 'orders': 1, 'points_earned': 1},
      'food': {'baht': 255, 'orders': 1, 'points_earned': 2},
      'parcel': {'baht': 33, 'orders': 1, 'points_earned': 0},
    };

    test('parsed from the summary; absent stays null', () {
      final s = LoyaltySummary.fromJson({
        'points': {'total_points': 9, 'lifetime_points': 12},
        'spending': sample,
      });
      expect(s.totalPoints, 9, reason: 'the balance, not lifetime');
      expect(s.spending!.total.baht, 408);
      expect(s.spending!.food.pointsEarned, 2);
      expect(s.spending!.parcel.orders, 1);
      expect(LoyaltySummary.fromJson({'points': {}}).spending, isNull);
    });

    testWidgets('คะแนนของฉัน no longer shows the spending card', (
      tester,
    ) async {
      // Even when the API still sends `spending`, the page leaves it out.
      await _pump(tester, _FakeLoyalty(spending: sample), initial: '/loyalty');
      expect(find.byKey(const Key('loyaltySpending')), findsNothing);
      expect(find.textContaining('ยอดรวม'), findsNothing);
      expect(find.text('1,250'), findsOneWidget);
    });
  });

  group('backend v2: rewards and vouchers', () {
    test('reward discount, per-user limit; voucher voided; points_spent', () {
      final r = Reward.fromJson({
        ..._reward('x'),
        'discount': {
          'type': 'PERCENT',
          'value': 20,
          'max_discount': 50,
          'min_spend': 100,
          'applies_to': 'FOOD',
          'stackable': true,
        },
        'per_user_limit': 2,
        'redeemed_by_me': 1,
      });
      expect(r.discount!.type, 'PERCENT');
      expect(r.discount!.maxDiscount, 50);
      expect(r.discount!.stackable, isTrue);
      expect(r.perUserLimit, 2);
      expect(r.redeemedByMe, 1);
      expect(Reward.fromJson(_reward('y')).perUserLimit, isNull);

      final v = Voucher.fromJson({
        ..._voucher('RW-VOID-0001', status: 'VOIDED'),
        'voided_at': '2026-11-01T03:00:00Z',
        'created_at': '2026-10-20T03:00:00Z',
        'image_url': 'https://cdn.test/r.png',
      });
      expect(v.status, 'VOIDED');
      expect(v.voidedAt, isNotNull);
      expect(v.imageUrl, 'https://cdn.test/r.png');

      final res = RedeemResult.fromJson({
        'voucher': _voucher('RW-1'),
        'points_spent': 80,
        'points_balance': 40,
        'replayed': true,
      });
      expect(res.pointsSpent, 80);
      expect(res.replayed, isTrue);
    });

    testWidgets('ยกเลิก tab: points returned', (tester) async {
      await _pump(tester, _FakeLoyalty(), initial: '/vouchers');
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(find.text('RW-VOID-0001'), findsOneWidget);
      expect(find.text('ยกเลิกแล้ว คืน 80 คะแนน'), findsOneWidget);
      expect(find.byKey(const Key('voucherUse-RW-VOID-0001')), findsNothing);
    });

    testWidgets('a 500 on redeem retries with the same key', (tester) async {
      final fake = _FakeLoyalty(
        rewards: [_reward('ok')],
        failFirstRedeemWith500: true,
      );
      await _pump(tester, fake);
      await tester.tap(find.byKey(const Key('rewardRedeem-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('redeemNoRefundNote')), findsOneWidget);
      await tester.tap(find.byKey(const Key('redeemConfirm')));
      await tester.pumpAndSettle();
      expect(find.text('ระบบขัดข้อง ลองใหม่อีกครั้ง'), findsOneWidget);
      await tester.tap(find.byKey(const Key('redeemConfirm')));
      await tester.pumpAndSettle();
      expect(fake.redeemKeys, hasLength(2));
      expect(fake.redeemKeys.toSet(), hasLength(1));
      expect(find.text('แลกสำเร็จ'), findsOneWidget);
    });
  });

  group('member tiers (ระดับสมาชิก)', () {
    const silver = {
      'code': 'SILVER',
      'name': 'Silver',
      'name_th': 'ซิลเวอร์',
      'name_en': 'Silver',
      'color': '#9AA0A6',
      'icon_url': null,
      'min_points': 0,
      'max_points': 999,
      'earn_multiplier': 1,
      'lifetime_points': 1400,
      'next_tier': {
        'code': 'GOLD',
        'name': 'Gold',
        'name_th': 'โกลด์',
        'name_en': 'Gold',
        'color': '#C9A227',
        'min_points': 1000,
      },
      'points_to_next': 250,
      'progress_percent': 75,
    };

    test('summary tier, colour, next tier; old fields as a fallback', () {
      final t = LoyaltySummary.fromJson({'tier': silver}).tier!;
      expect(t.code, 'SILVER');
      expect(t.displayName('th'), 'ซิลเวอร์');
      expect(t.displayName('en'), 'Silver');
      expect(t.color, 0xFF9AA0A6);
      expect(t.iconUrl, isNull);
      expect(t.nextTier!.displayName('th'), 'โกลด์');
      expect(t.pointsToNext, 250);
      expect(t.progressPercent, 75);
      expect(t.isTop, isFalse);

      final top = LoyaltyTier.fromJson({
        'code': 'GOLD',
        'name': 'Gold',
        'next_tier': null,
        'progress_percent': 100,
        'earn_multiplier': 1.5,
      })!;
      expect(top.isTop, isTrue);
      expect(top.earnMultiplier, 1.5);

      final legacy = LoyaltySummary.fromJson({
        'current_tier': 'Silver',
        'next_tier_points': 300,
      }).tier!;
      expect(legacy.name, 'Silver');
      expect(legacy.pointsToNext, 300);
      expect(LoyaltySummary.fromJson(const {}).tier, isNull);
      expect(parseHexColor('C9A227'), 0xFFC9A227);
      expect(parseHexColor('nope'), isNull);
    });

    testWidgets('คะแนนของฉัน shows the badge, bar and points to next', (
      tester,
    ) async {
      await _pump(tester, _FakeLoyalty(tier: silver), initial: '/loyalty');
      final ladder = find.byKey(const Key('tierProgressCard'));
      expect(ladder, findsOneWidget);
      // Every tier in the list, the customer's marked, the next with its gap.
      expect(find.byKey(const Key('tierLadder-SILVER')), findsOneWidget);
      expect(find.byKey(const Key('tierLadder-GOLD')), findsOneWidget);
      expect(
        find.descendant(of: ladder, matching: find.text('ระดับของคุณ')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: ladder, matching: find.text('อีก 250 คะแนน')),
        findsOneWidget,
      );
      // The MASS POINTS card carries the same tier badge as the profile.
      expect(find.byKey(const Key('tierBadge')), findsOneWidget);
      expect(find.byKey(const Key('tierDot')), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('tierProgress')),
      );
      expect(bar.value, 0.75);
      expect(find.text('อีก 250 คะแนนถึง โกลด์'), findsOneWidget);
      // ×1: no multiplier line.
      expect(find.byKey(const Key('tierMultiplier')), findsNothing);
    });

    testWidgets('top tier: full bar, top text, multiplier', (tester) async {
      await _pump(
        tester,
        _FakeLoyalty(
          tier: {
            'code': 'GOLD',
            'name': 'Gold',
            'name_th': 'โกลด์',
            'color': '#C9A227',
            'earn_multiplier': 1.5,
            'next_tier': null,
            'progress_percent': 100,
          },
        ),
        initial: '/loyalty',
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('tierProgress')),
            )
            .value,
        1.0,
      );
      expect(find.text('คุณอยู่ระดับสูงสุดแล้ว'), findsOneWidget);
      expect(find.text('ได้คะแนน ×1.5'), findsOneWidget);
    });

    testWidgets('the tier list keeps the order and marks mine', (tester) async {
      await _pump(tester, _FakeLoyalty(tier: silver), initial: '/loyalty');
      await tester.tap(find.byKey(const Key('tierProgressCard')));
      await tester.pumpAndSettle();
      final silverY = tester
          .getTopLeft(find.byKey(const Key('tierCard-SILVER')))
          .dy;
      final goldY = tester
          .getTopLeft(find.byKey(const Key('tierCard-GOLD')))
          .dy;
      expect(silverY, lessThan(goldY));
      expect(find.text('0–999 คะแนน'), findsOneWidget);
      expect(find.text('1,000 คะแนนขึ้นไป'), findsOneWidget);
      expect(find.text('คูปองวันเกิด'), findsOneWidget);
      expect(find.byKey(const Key('tierYours')), findsOneWidget);
    });
  });
}
