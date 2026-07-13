import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkout_state.freezed.dart';

@freezed
abstract class CheckoutState with _$CheckoutState {
  const factory CheckoutState({
    @Default(false) bool wantCutlery,
    @Default('STANDARD') String selectedDeliveryOption,
    @Default('') String floorUnit,
    String? appliedPromoCode,
    @Default('CASH') String paymentMethod,
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
  }) = _CheckoutState;
}
