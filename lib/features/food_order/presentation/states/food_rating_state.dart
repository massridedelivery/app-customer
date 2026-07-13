import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_rating_state.freezed.dart';

@freezed
abstract class FoodRatingState with _$FoodRatingState {
  const factory FoodRatingState({
    @Default(true) bool isLoading,
    FoodOrderModel? order,
    RestaurantProfileModel? restaurant,
    String? error,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSubmitSuccess,
  }) = _FoodRatingState;
}
