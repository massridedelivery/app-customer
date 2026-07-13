import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_cart.freezed.dart';
part 'remote_cart.g.dart';

/// Response of `GET /api/food/customer/cart` (SCRUM-44 Screen 4).
///
/// Items are **thin** — the server resolves names/prices but references items
/// by `menu_item_id` and modifiers by name (no ids, no full menu item). The
/// client rebuilds full `CartItem`s by matching these against the restaurant
/// menu (see FoodCartController restore).
@freezed
abstract class RemoteCart with _$RemoteCart {
  const factory RemoteCart({
    @JsonKey(name: 'restaurant_id') @Default('') String restaurantId,
    @JsonKey(name: 'restaurant_name') @Default('') String restaurantName,
    @Default([]) List<RemoteCartItem> items,
  }) = _RemoteCart;

  factory RemoteCart.fromJson(Map<String, dynamic> json) =>
      _$RemoteCartFromJson(json);
}

@freezed
abstract class RemoteCartItem with _$RemoteCartItem {
  const factory RemoteCartItem({
    @JsonKey(name: 'menu_item_id') @Default('') String menuItemId,
    @Default(1) int quantity,
    @JsonKey(name: 'modifier_names') @Default([]) List<String> modifierNames,
    @Default('') String notes,
  }) = _RemoteCartItem;

  factory RemoteCartItem.fromJson(Map<String, dynamic> json) =>
      _$RemoteCartItemFromJson(json);
}
