import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/services/idempotency.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/states/checkout_state.dart';
import 'package:customer_app/features/food_order/presentation/states/food_cart_state.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_cart_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'checkout_controller.g.dart';

@riverpod
class Checkout extends _$Checkout {
  /// What the last estimate was for, so switching points or codes can price
  /// it again.
  ({String restaurantId, List<CartItem> cartItems, double lat, double lng})?
  _lastEstimate;

  @override
  CheckoutState build() {
    return const CheckoutState();
  }

  /// 🪙 ใช้คะแนน on/off: the estimate says how many points and what's left
  /// to pay.
  void setUsePoints(bool value) {
    if (state.usePoints == value) return;
    state = state.copyWith(usePoints: value);
    _reestimate();
  }

  /// Prices the order again with the current codes and points.
  Future<void> _reestimate() async {
    final last = _lastEstimate;
    if (last == null) return;
    await loadEstimate(
      restaurantId: last.restaurantId,
      cartItems: last.cartItems,
      lat: last.lat,
      lng: last.lng,
      withSuggestions: false,
    );
  }

  void updateWantCutlery(bool value) {
    state = state.copyWith(wantCutlery: value);
  }

  void updateDeliveryOption(String value) {
    state = state.copyWith(selectedDeliveryOption: value);
    final cartState = ref.read(foodCartControllerProvider);
    if (cartState.restaurantId != null) {
      loadSuggestions(restaurantId: cartState.restaurantId!);
    }
  }

  void updateFloorUnit(String value) {
    state = state.copyWith(floorUnit: value);
  }

  void updatePromoCode(String? value) {
    if (value == null) {
      state = state.copyWith(
        appliedPromoCodes: [],
        appliedPromoCode: null,
        validatedPromoDiscount: 0.0,
        promoError: null,
      );
    } else {
      togglePromoCode(value);
    }
  }

  void togglePromoCode(String code) {
    final codes = List<String>.from(state.appliedPromoCodes);
    if (codes.contains(code)) {
      codes.remove(code);
    } else {
      codes.add(code);
    }
    state = state.copyWith(appliedPromoCodes: codes);
    // With points on, what's left to pay depends on the codes too.
    if (state.usePoints) _reestimate();

    if (codes.isEmpty) {
      state = state.copyWith(
        appliedPromoCode: null,
        validatedPromoDiscount: 0.0,
        promoError: null,
      );
    } else {
      state = state.copyWith(appliedPromoCode: codes.first);

      final cartNotifier = ref.read(foodCartControllerProvider.notifier);
      final subtotal = cartNotifier.foodTotal;
      final restaurantId = ref.read(foodCartControllerProvider).restaurantId ?? '';

      // Calculate delivery fee
      double deliveryFee = 0.0;
      final tiers = state.estimate?.tiers ?? [];
      DeliveryTierModel? selectedTier;
      for (final t in tiers) {
        if (t.tier == state.selectedDeliveryOption) {
          selectedTier = t;
          break;
        }
      }
      if (selectedTier != null) {
        deliveryFee = selectedTier.deliveryFee;
      } else {
        if (state.selectedDeliveryOption == 'PRIORITY') {
          deliveryFee = 45;
        } else if (state.selectedDeliveryOption == 'SAVER') {
          deliveryFee = 15;
        } else {
          deliveryFee = 25;
        }
      }

      validateStackedPromos(
        codes: codes,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        restaurantId: restaurantId,
      );
    }
  }

  Future<void> validateStackedPromos({
    required List<String> codes,
    required double subtotal,
    required double deliveryFee,
    required String restaurantId,
  }) async {
    state = state.copyWith(isPromoLoading: true, promoError: null);
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      final result = await repo.validateStackedPromos(
        promoCodes: codes,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        restaurantId: restaurantId,
      );
      state = state.copyWith(
        isPromoLoading: false,
        validatedPromoDiscount: result.totalDiscount,
        promoError: null,
      );
    } catch (e) {
      state = state.copyWith(
        isPromoLoading: false,
        promoError: e.toString(),
        validatedPromoDiscount: 0.0,
      );
    }
  }

  Future<void> fetchAvailablePromos() async {
    state = state.copyWith(isPromoLoading: true, promoError: null);
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      final cartState = ref.read(foodCartControllerProvider);
      final restaurantId = cartState.restaurantId;

      final List<PromoModel> promos;
      if (restaurantId != null && restaurantId.isNotEmpty) {
        promos = await repo.getPromoContext(
          appliesTo: 'FOOD',
          merchantId: restaurantId,
        );
      } else {
        promos = await repo.getPromoList();
      }

      state = state.copyWith(
        isPromoLoading: false,
        availablePromos: promos,
      );
    } catch (e) {
      state = state.copyWith(
        isPromoLoading: false,
        promoError: e.toString(),
      );
    }
  }

  Future<void> validatePromo(String code, double fare) async {
    state = state.copyWith(isPromoLoading: true, promoError: null);
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      final result = await repo.validatePromoCode(code: code, fare: fare);
      if (result.isValid) {
        state = state.copyWith(
          isPromoLoading: false,
          validatedPromoDiscount: result.discountAmount,
          appliedPromoCode: code,
          promoError: null,
        );
      } else {
        state = state.copyWith(
          isPromoLoading: false,
          promoError: result.message ?? 'คูปองไม่สามารถใช้งานได้',
          validatedPromoDiscount: 0.0,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isPromoLoading: false,
        promoError: e.toString(),
        validatedPromoDiscount: 0.0,
      );
    }
  }

  void updatePaymentMethod(String value) {
    state = state.copyWith(paymentMethod: value);
  }

  Future<void> loadEstimate({
    required String restaurantId,
    required List<CartItem> cartItems,
    required double lat,
    required double lng,
    bool withSuggestions = true,
  }) async {
    _lastEstimate = (
      restaurantId: restaurantId,
      cartItems: cartItems,
      lat: lat,
      lng: lng,
    );
    state = state.copyWith(
      // Only the first estimate covers the page; pricing it again (points,
      // codes) keeps the page as it is.
      isLoading: state.estimate == null,
      error: null,
      placedOrder: null,
      idempotencyKey: state.idempotencyKey ?? generateIdempotencyKey(),
    );
    try {
      final repo = ref.read(foodOrderRepositoryProvider);

      // Include modifier_ids so the fee reflects modifier weight/price
      // (SCRUM-44 Screen 5 estimate request), mirroring the place-order body.
      final itemsPayload = cartItems
          .map(
            (e) => {
              'menu_item_id': e.item.id,
              'quantity': e.quantity,
              if (e.selectedModifiers.isNotEmpty)
                'modifier_ids': e.selectedModifiers.map((m) => m.id).toList(),
            },
          )
          .toList();

      // With points on, the codes go along so each tier's `amount_to_pay`
      // is after both (the codes are otherwise checked on their own, see
      // [validateStackedPromos]). A code the estimate refuses mustn't take
      // the tiers away: price it again without the codes.
      final codes = state.usePoints && state.appliedPromoCodes.isNotEmpty
          ? state.appliedPromoCodes
          : null;
      FareEstimateResponseModel estimate;
      try {
        estimate = await repo.getFareEstimate(
          restaurantId: restaurantId,
          items: itemsPayload,
          lat: lat,
          lng: lng,
          promoCodes: codes,
          usePoints: state.usePoints,
        );
      } on ApiError catch (e) {
        if (codes == null || !(e.code ?? '').startsWith('VOUCHER_')) rethrow;
        state = state.copyWith(promoError: e.message);
        estimate = await repo.getFareEstimate(
          restaurantId: restaurantId,
          items: itemsPayload,
          lat: lat,
          lng: lng,
          usePoints: state.usePoints,
        );
      }

      state = state.copyWith(isLoading: false, estimate: estimate);
      if (withSuggestions) await loadSuggestions(restaurantId: restaurantId);
    } on ApiError catch (e) {
      // A refused point redemption: drop points if they can't be used at
      // all, keep the message, and price it without them.
      if (_pointsOff(e.code) && state.usePoints) {
        state = state.copyWith(isLoading: false, usePoints: false);
        await _reestimate();
        state = state.copyWith(error: e.message);
        return;
      }
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadSuggestions({required String restaurantId}) async {
    state = state.copyWith(isSuggestionsLoading: true);
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      final cartNotifier = ref.read(foodCartControllerProvider.notifier);
      final subtotal = cartNotifier.foodTotal;

      double deliveryFee = 0.0;
      final tiers = state.estimate?.tiers ?? [];
      DeliveryTierModel? selectedTier;
      for (final t in tiers) {
        if (t.tier == state.selectedDeliveryOption) {
          selectedTier = t;
          break;
        }
      }

      if (selectedTier != null) {
        deliveryFee = selectedTier.deliveryFee;
      } else {
        if (state.selectedDeliveryOption == 'PRIORITY') {
          deliveryFee = 45;
        } else if (state.selectedDeliveryOption == 'SAVER') {
          deliveryFee = 15;
        } else {
          deliveryFee = 25;
        }
      }

      final suggestions = await repo.getPromoSuggestions(
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        restaurantId: restaurantId,
      );

      state = state.copyWith(
        isSuggestionsLoading: false,
        suggestions: suggestions,
      );

      // Auto-select/enable the checkbox for recommended: true and status: USABLE promo
      for (final suggestion in suggestions) {
        if (suggestion.recommended && suggestion.status == 'USABLE') {
          if (state.appliedPromoCode != suggestion.promo.code) {
            updatePromoCode(suggestion.promo.code);
          }
        }
      }
    } catch (e) {
      state = state.copyWith(isSuggestionsLoading: false);
    }
  }

  Future<FoodOrderModel?> placeOrder({
    required String restaurantId,
    required List<CartItem> cartItems,
    required double lat,
    required double lng,
    String? address,
    String? notes,
    String? paymentMethod,
    String? tier,
    List<String>? promoCodes,
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isPlacingOrder: true, error: null);
    try {
      final repo = ref.read(foodOrderRepositoryProvider);

      final itemsPayload = cartItems
          .map(
            (e) => {
              'menu_item_id': e.item.id,
              'quantity': e.quantity,
              if (e.selectedModifiers.isNotEmpty)
                'modifier_ids': e.selectedModifiers.map((m) => m.id).toList(),
              if (e.notes.isNotEmpty) 'notes': e.notes,
            },
          )
          .toList();

      final order = await repo.placeOrder(
        restaurantId: restaurantId,
        items: itemsPayload,
        lat: lat,
        lng: lng,
        address: address,
        notes: notes,
        paymentMethod: paymentMethod?.toUpperCase() ?? 'CASH',
        tier: tier?.toUpperCase() ?? 'STANDARD',
        promoCodes: promoCodes,
        idempotencyKey: idempotencyKey,
        usePoints: state.spendsPoints,
      );

      state = state.copyWith(isPlacingOrder: false, placedOrder: order);
      // Points (and vouchers) were spent: the balance and coupons changed.
      ref.invalidate(loyaltySummaryProvider);
      return order;
    } on ApiError catch (e) {
      // POINTS_*: turn points off when they can't be used at all, then price
      // again. VOUCHER_UNAVAILABLE: the voucher went elsewhere meanwhile —
      // drop it and price again. Either way the server's text is shown.
      final code = e.code ?? '';
      if (code.startsWith('POINTS_')) {
        state = state.copyWith(
          isPlacingOrder: false,
          usePoints: _pointsOff(code) ? false : state.usePoints,
        );
        await _reestimate();
      } else if (code == 'VOUCHER_UNAVAILABLE') {
        state = state.copyWith(isPlacingOrder: false);
        await _reestimate();
        await fetchAvailablePromos();
      }
      state = state.copyWith(isPlacingOrder: false, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isPlacingOrder: false, error: e.toString());
      return null;
    }
  }

  Future<void> submitOrder({
    required String restaurantId,
    required List<CartItem> cartItems,
    required double lat,
    required double lng,
    required String address,
    double? payable,
  }) async {
    if (restaurantId.isEmpty || cartItems.isEmpty) {
      state = state.copyWith(error: 'ไม่มีสินค้าในตะกร้า');
      return;
    }

    final notes = state.floorUnit.isNotEmpty ? '${state.floorUnit} ' : '';

    final key = state.idempotencyKey ?? generateIdempotencyKey();
    if (state.idempotencyKey == null) {
      state = state.copyWith(idempotencyKey: key);
    }

    await placeOrder(
      restaurantId: restaurantId,
      cartItems: cartItems,
      lat: lat,
      lng: lng,
      address: address,
      notes: notes,
      // Nothing left to pay (a coupon covers it all): no QR to scan.
      paymentMethod: payable != null && payable <= 0
          ? 'CASH'
          : state.paymentMethod,
      tier: state.selectedDeliveryOption,
      promoCodes: state.appliedPromoCodes.isNotEmpty
          ? state.appliedPromoCodes
          : null,
      idempotencyKey: key,
    );
  }

  /// Refusals after which points can't be used on this order at all.
  static bool _pointsOff(String? code) =>
      code == 'POINTS_DISABLED' || code == 'POINTS_LOGIN_REQUIRED';
}
