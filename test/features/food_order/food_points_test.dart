import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/domain/repositories/i_food_order_repository.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:customer_app/features/food_order/presentation/states/food_cart_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _tier({
  bool points = true,
  int used = 0,
  double? toPay,
  String? reason,
}) => {
  'tier': 'STANDARD',
  'display_name': 'มาตรฐาน',
  'delivery_fee': 25,
  'estimated_min': 30,
  'promo_discount': 0,
  'amount_to_pay': ?toPay,
  if (points)
    'points': {
      'enabled': true,
      'balance': 120,
      'baht_per_point': 1,
      'min_redeem': 10,
      'max_usable_points': 80,
      'used_points': used,
      'discount': used.toDouble(),
      'reason_unavailable': reason,
    },
};

FareEstimateResponseModel _estimate(Map<String, dynamic> tier) =>
    FareEstimateResponseModel.fromJson({
      'base_fee': 25,
      'distance_km': 2.1,
      'food_total': 105,
      'tiers': [tier],
    });

class _Repo implements IFoodOrderRepository {
  final estimates = <({List<String>? codes, bool usePoints})>[];
  final orders = <bool>[];
  Object? orderError;

  @override
  Future<FareEstimateResponseModel> getFareEstimate({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double lat,
    required double lng,
    List<String>? promoCodes,
    bool usePoints = false,
    int? pointsToUse,
  }) async {
    estimates.add((codes: promoCodes, usePoints: usePoints));
    return usePoints
        ? _estimate(_tier(used: 80, toPay: 50))
        : _estimate(_tier(toPay: 130));
  }

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
    bool usePoints = false,
    int? pointsToUse,
  }) async {
    orders.add(usePoints);
    final e = orderError;
    if (e != null) throw e;
    return const FoodOrderModel(id: 'o1');
  }

  @override
  Future<List<PromoSuggestionModel>> getPromoSuggestions({
    required double subtotal,
    required double deliveryFee,
    required String restaurantId,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _cart = [
  CartItem(
    item: MenuItemModel(
      id: 'm1',
      categoryId: 'c1',
      name: 'Pad Thai',
      nameTh: 'ผัดไทย',
      price: 105,
    ),
    quantity: 1,
  ),
];

void main() {
  test('a tier reads points, promo_discount and amount_to_pay', () {
    final t = DeliveryTierModel.fromJson(_tier(used: 80, toPay: 50));
    expect(t.amountToPay, 50);
    expect(t.promoDiscount, 0);
    expect(t.points!.usable, isTrue);
    expect(t.points!.usedPoints, 80);
    expect(
      DeliveryTierModel.fromJson(_tier(reason: 'BELOW_MIN')).points!.usable,
      isFalse,
    );
    expect(DeliveryTierModel.fromJson(_tier(points: false)).points, isNull);
  });

  group('checkout', () {
    late _Repo repo;
    late ProviderContainer c;

    Checkout n() => c.read(checkoutProvider.notifier);

    setUp(() async {
      repo = _Repo();
      c = ProviderContainer(
        overrides: [foodOrderRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      c.listen(checkoutProvider, (_, _) {});
      await n().loadEstimate(
        restaurantId: 'r1',
        cartItems: _cart,
        lat: 13.7,
        lng: 100.5,
      );
    });

    test(
      'switching points on prices it again and the order spends them',
      () async {
        expect(repo.estimates.last.usePoints, isFalse);
        expect(c.read(checkoutProvider).spendsPoints, isFalse);

        n().setUsePoints(true);
        await Future<void>.delayed(Duration.zero);
        expect(repo.estimates.last.usePoints, isTrue);
        final s = c.read(checkoutProvider);
        expect(s.spendsPoints, isTrue);
        expect(s.selectedTier!.amountToPay, 50);

        await n().submitOrder(
          restaurantId: 'r1',
          cartItems: _cart,
          lat: 13.7,
          lng: 100.5,
          address: 'บ้าน',
        );
        expect(repo.orders.single, isTrue);
      },
    );

    test('points off: the order sends no use_points', () async {
      await n().submitOrder(
        restaurantId: 'r1',
        cartItems: _cart,
        lat: 13.7,
        lng: 100.5,
        address: 'บ้าน',
      );
      expect(repo.orders.single, isFalse);
    });

    test(
      'POINTS_DISABLED switches points off, prices again, shows the text',
      () async {
        n().setUsePoints(true);
        await Future<void>.delayed(Duration.zero);
        repo.orderError = const ApiError(
          message: 'ปิดการใช้คะแนนชั่วคราว',
          code: 'POINTS_DISABLED',
          statusCode: 409,
        );
        final before = repo.estimates.length;
        await n().submitOrder(
          restaurantId: 'r1',
          cartItems: _cart,
          lat: 13.7,
          lng: 100.5,
          address: 'บ้าน',
        );
        final s = c.read(checkoutProvider);
        expect(s.usePoints, isFalse);
        expect(s.error, 'ปิดการใช้คะแนนชั่วคราว');
        expect(repo.estimates.length, before + 1);
        expect(repo.estimates.last.usePoints, isFalse);
      },
    );

    test('POINTS_INSUFFICIENT keeps points on and prices again', () async {
      n().setUsePoints(true);
      await Future<void>.delayed(Duration.zero);
      repo.orderError = const ApiError(
        message: 'คะแนนไม่พอ',
        code: 'POINTS_INSUFFICIENT',
        statusCode: 409,
      );
      await n().submitOrder(
        restaurantId: 'r1',
        cartItems: _cart,
        lat: 13.7,
        lng: 100.5,
        address: 'บ้าน',
      );
      final s = c.read(checkoutProvider);
      expect(s.usePoints, isTrue);
      expect(s.error, 'คะแนนไม่พอ');
    });
  });
}
