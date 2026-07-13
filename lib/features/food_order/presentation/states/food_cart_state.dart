import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_cart_state.freezed.dart';
part 'food_cart_state.g.dart';

@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    required MenuItemModel item,
    required int quantity,
    @Default([]) List<ModifierModel> selectedModifiers,
    String? variantOptions,
    // Per-item special instructions (SCRUM-44 Screen 4, `items[].notes` ≤200).
    @Default('') String notes,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}

@freezed
abstract class FoodCartState with _$FoodCartState {
  const factory FoodCartState({
    String? restaurantId,
    String? restaurantName,
    String? restaurantImageUrl,
    @Default([]) List<CartItem> items,
  }) = _FoodCartState;

  factory FoodCartState.fromJson(Map<String, dynamic> json) =>
      _$FoodCartStateFromJson(json);
}
