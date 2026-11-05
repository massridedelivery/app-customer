import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_quote.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkout_state.freezed.dart';

@freezed
abstract class CheckoutState with _$CheckoutState {
  const factory CheckoutState({
    @Default(false) bool wantCutlery,
    @Default('STANDARD') String selectedDeliveryOption,
    @Default('') String floorUnit,
    String? appliedPromoCode,
    // PromptPay first; the customer can still switch to cash.
    @Default('PROMPTPAY') String paymentMethod,
    String? idempotencyKey,
    @Default(false) bool isLoading,
    @Default(false) bool isPlacingOrder,
    FareEstimateResponseModel? estimate,
    String? error,
    FoodOrderModel? placedOrder,
    @Default([]) List<PromoModel> availablePromos,
    @Default(false) bool isPromoLoading,
    String? promoError,
    @Default(0.0) double validatedPromoDiscount,
    @Default([]) List<PromoSuggestionModel> suggestions,
    @Default(false) bool isSuggestionsLoading,
    @Default([]) List<String> appliedPromoCodes,
    // 🪙 ใช้คะแนน: on = every point this order allows.
    @Default(false) bool usePoints,
  }) = _CheckoutState;

  const CheckoutState._();

  /// The tier the customer picked, from the latest estimate.
  DeliveryTierModel? get selectedTier {
    for (final t in estimate?.tiers ?? const <DeliveryTierModel>[]) {
      if (t.tier == selectedDeliveryOption) return t;
    }
    return null;
  }

  /// Points for the selected tier (null when the estimate has none).
  RidePointsQuote? get pointsQuote => selectedTier?.points;

  /// Points are on and this order can use some.
  bool get spendsPoints =>
      usePoints && (pointsQuote?.usable ?? false) && pointsQuote!.usedPoints > 0;
}
