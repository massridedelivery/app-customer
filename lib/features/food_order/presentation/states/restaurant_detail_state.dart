import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'restaurant_detail_state.freezed.dart';

@freezed
abstract class RestaurantDetailState with _$RestaurantDetailState {
  const factory RestaurantDetailState({
    @Default(true) bool isLoading,
    RestaurantProfileModel? restaurant,
    @Default([]) List<MenuCategoryModel> menuCategories,
    @Default([]) List<PromoModel> promos,
    String? error,
  }) = _RestaurantDetailState;
}
