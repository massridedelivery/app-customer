import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/features/profile/data/datasources/loyalty_remote_data_source.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/profile/presentation/screens/loyalty_screen.dart';
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
  _FakeLoyalty({this.rewards = const [], this.failFirstRedeem = false});

  final List<Map<String, dynamic>> rewards;
  bool failFirstRedeem;
  final redeemKeys = <String>[];

  @override
  Future<Map<String, dynamic>> getSummary() async => {
    'points': {'total_points': 1250, 'lifetime_points': 1400},
    'points_enabled': true,
    'points_baht_value': 1,
    'balance_baht': 1250,
    'expiring_soon': {'points': 120, 'expires_at': '2026-11-10T03:12:00Z'},
    'earn_per_100_baht': {'ride': 1, 'min_order': 50},
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
      GoRoute(path: '/loyalty', builder: (_, _) => const LoyaltyScreen()),
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
    expect(find.text('รับ 1 คะแนนทุก ฿100 ที่จ่าย (ขั้นต่ำ ฿50)'), findsOneWidget);
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
    expect(find.byKey(const Key('voucherExpiringSoon')), findsOneWidget);
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
}
