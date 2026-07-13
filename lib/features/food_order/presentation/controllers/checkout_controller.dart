import 'dart:math';
import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/states/checkout_state.dart';
import 'package:customer_app/features/food_order/presentation/states/food_cart_state.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_cart_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'checkout_controller.g.dart';

@riverpod
class Checkout extends _$Checkout {
  @override
  CheckoutState build() {
    return const CheckoutState();
  }

  String _generateUuid() {
    final random = Random();
    const hexDigits = '0123456789abcdef';
    final charCodes = List<int>.generate(36, (index) {
      if (index == 8 || index == 13 || index == 18 || index == 23) {
        return 45; // '-' character
      }
      return hexDigits.codeUnitAt(random.nextInt(16));
    });
    return String.fromCharCodes(charCodes);
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
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      placedOrder: null,
      idempotencyKey: state.idempotencyKey ?? _generateUuid(),
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

      final estimate = await repo.getFareEstimate(
        restaurantId: restaurantId,
        items: itemsPayload,
        lat: lat,
        lng: lng,
      );

      state = state.copyWith(isLoading: false, estimate: estimate);
      await loadSuggestions(restaurantId: restaurantId);
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
      );

      state = state.copyWith(isPlacingOrder: false, placedOrder: order);
      return order;
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
  }) async {
    if (restaurantId.isEmpty || cartItems.isEmpty) {
      state = state.copyWith(error: 'ไม่มีสินค้าในตะกร้า');
      return;
    }

    final notes = state.floorUnit.isNotEmpty ? '${state.floorUnit} ' : '';

    final key = state.idempotencyKey ?? _generateUuid();
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
      paymentMethod: state.paymentMethod,
      tier: state.selectedDeliveryOption,
      promoCodes: state.appliedPromoCodes.isNotEmpty
          ? state.appliedPromoCodes
          : null,
      idempotencyKey: key,
    );
  }
}
