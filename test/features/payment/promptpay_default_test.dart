import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/domain/repositories/i_food_order_repository.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:customer_app/features/food_order/presentation/controllers/live_food_tracking_controller.dart';
import 'package:customer_app/features/food_order/presentation/states/checkout_state.dart';
import 'package:customer_app/features/food_order/presentation/states/food_cart_state.dart';
import 'package:customer_app/features/food_order/presentation/states/live_food_tracking_state.dart';
import 'package:customer_app/features/food_order/presentation/widgets/live_food_tracking_pay_now.dart';
import 'package:customer_app/features/messenger/presentation/states/messenger_booking_state.dart';
import 'package:customer_app/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:customer_app/features/payment/domain/models/payment_intent.dart';
import 'package:customer_app/features/payment/domain/repositories/i_payment_repository.dart';
import 'package:customer_app/features/payment/presentation/screens/promptpay_qr_screen.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QuietSocket extends SocketService {
  _QuietSocket(super.tokenStorage);

  @override
  void connect({bool isReconnect = false}) {}

  @override
  void disconnect() {}
}

/// Records the payment method each order is placed with.
class _FoodRepo implements IFoodOrderRepository {
  final List<String?> placedWith = [];

  @override
  Future<FoodOrderModel> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double lat,
    required double lng,
    String? address,
    String? notes,
    String? paymentMethod,
    String? tier,
    List<String>? promoCodes,
    String? idempotencyKey,
  }) async {
    placedWith.add(paymentMethod);
    return FoodOrderModel(id: 'order-1', paymentMethod: paymentMethod ?? '');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Creating a QR for an order always fails, so the QR screen shows its error
/// view (where the "pay cash instead" button lives).
class _FailingPaymentRepo implements IPaymentRepository {
  @override
  Future<PaymentIntent> createIntentForOrder({
    required String orderId,
    required String paymentMethod,
    String? cardToken,
  }) async => throw Exception('no QR');

  @override
  Future<PaymentIntent?> getIntentByOrder(String orderId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTracking extends LiveFoodTrackingController {
  _FakeTracking(this.initial);

  final LiveFoodTrackingState initial;

  @override
  LiveFoodTrackingState build() => initial;
}

const _cart = [
  CartItem(
    item: MenuItemModel(
      id: 'm1',
      categoryId: 'c1',
      name: 'Rice',
      nameTh: 'ข้าว',
      price: 50,
    ),
    quantity: 1,
  ),
];

Future<void> _placeFood(ProviderContainer c, {required double payable}) =>
    c.read(checkoutProvider.notifier).submitOrder(
      restaurantId: 'r1',
      cartItems: _cart,
      lat: 13.7,
      lng: 100.5,
      address: 'บ้าน',
      payable: payable,
    );

/// A router whose `/` opens [first]; other routes are stubs that show their
/// path and the `extra` they were opened with.
GoRouter _router(String first, {Object? extra}) {
  Widget stub(GoRouterState s) => Scaffold(
    body: Text('at ${s.uri.path} ${s.extra ?? ''}'),
  );
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(first, extra: extra),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/payment/promptpay',
        builder: (_, s) {
          final e = s.extra as Map<String, dynamic>? ?? {};
          return e['real'] == true
              ? PromptPayQrScreen(
                  orderId: e['orderId'] as String?,
                  onPaidRoute: e['onPaidRoute'] as String?,
                  exitRoute: e['exitRoute'] as String?,
                )
              : stub(s);
        },
      ),
      GoRoute(path: '/food-order/tracking/:id', builder: (_, s) => stub(s)),
      GoRoute(path: '/pay-now', builder: (_, _) => const _PayNowHost()),
    ],
  );
}

class _PayNowHost extends StatelessWidget {
  const _PayNowHost();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: LiveFoodTrackingPayNow(orderId: 'order-1'));
}

Future<void> _pumpApp(
  WidgetTester tester,
  GoRouter router,
  List overrides,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  test('PromptPay is the default everywhere', () {
    expect(const BookingState().paymentMethod, 'PROMPTPAY');
    expect(const MessengerBookingState().paymentMethod, 'PROMPTPAY');
    expect(const CheckoutState().paymentMethod, 'PROMPTPAY');
  });

  group('food checkout', () {
    late _FoodRepo repo;
    late ProviderContainer c;

    setUp(() {
      repo = _FoodRepo();
      c = ProviderContainer(
        overrides: [foodOrderRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      c.listen(checkoutProvider, (_, _) {});
    });

    test('places the order with PromptPay by default', () async {
      await _placeFood(c, payable: 120);
      expect(repo.placedWith, ['PROMPTPAY']);
    });

    test('nothing left to pay: cash, so there is no QR', () async {
      await _placeFood(c, payable: 0);
      expect(repo.placedWith, ['CASH']);
    });

    test('a customer who picked cash keeps cash', () async {
      c.read(checkoutProvider.notifier).updatePaymentMethod('CASH');
      await _placeFood(c, payable: 120);
      expect(repo.placedWith, ['CASH']);
    });
  });

  group('food QR screen', () {
    testWidgets('no cash fallback, and leaving goes to tracking', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const tracking = '/food-order/tracking/order-1';
      await _pumpApp(
        tester,
        _router(
          '/payment/promptpay',
          extra: {
            'real': true,
            'orderId': 'order-1',
            'onPaidRoute': tracking,
            'exitRoute': tracking,
          },
        ),
        [
          paymentRepositoryProvider.overrideWithValue(_FailingPaymentRepo()),
          socketServiceProvider.overrideWithValue(
            _QuietSocket(TokenStorage(prefs)),
          ),
        ],
      );

      expect(find.text('สร้าง QR ไม่สำเร็จ'), findsOneWidget);
      expect(find.text('จ่ายเงินสดแทน'), findsNothing);

      // The app-bar back button (the system back takes the same path).
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('at $tracking'), findsOneWidget);
    });
  });

  group('food tracking pay-now card', () {
    LiveFoodTrackingState held({
      String method = 'PROMPTPAY',
      String? paymentStatus = 'PENDING',
      String status = 'PLACED',
    }) => LiveFoodTrackingState(
      orderId: 'order-1',
      order: FoodOrderModel(
        id: 'order-1',
        status: status,
        paymentMethod: method,
        paymentStatus: paymentStatus,
      ),
    );

    Future<void> pump(WidgetTester tester, LiveFoodTrackingState s) =>
        _pumpApp(tester, _router('/pay-now'), [
          liveFoodTrackingControllerProvider.overrideWith(
            () => _FakeTracking(s),
          ),
        ]);

    testWidgets('an unpaid PromptPay order offers to pay', (tester) async {
      await pump(tester, held());
      expect(find.text('ยังไม่ได้ชำระเงิน'), findsOneWidget);

      await tester.tap(find.byKey(const Key('foodPayNowButton')));
      await tester.pumpAndSettle();
      expect(find.textContaining('at /payment/promptpay'), findsOneWidget);
      expect(find.textContaining('orderId: order-1'), findsOneWidget);
      expect(
        find.textContaining('exitRoute: /food-order/tracking/order-1'),
        findsOneWidget,
      );
    });

    testWidgets('hidden once paid, for cash, and when cancelled', (
      tester,
    ) async {
      for (final s in [
        held(paymentStatus: 'PAID'),
        held(method: 'CASH', paymentStatus: null),
        held(status: 'CANCELLED'),
      ]) {
        await pump(tester, s);
        expect(find.byKey(const Key('foodPayNow')), findsNothing);
      }
    });
  });
}
