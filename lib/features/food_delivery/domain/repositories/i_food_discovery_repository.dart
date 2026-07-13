import 'package:customer_app/features/food_order/domain/models/food_models.dart';

abstract interface class IFoodDiscoveryRepository {
  Future<HomeResponseModel> getHomeFeed({
    required double lat,
    required double lng,
  });
  Future<List<RestaurantProfileModel>> searchRestaurants({
    required String query,
    required double lat,
    required double lng,
    int? limit,
    int? offset,
    String? category,
    bool? isOpen,
    double? maxDistance,
  });
  Future<List<CategoryModel>> getCategories();
  Future<List<RestaurantProfileModel>> getCategoryRestaurants({
    required String categoryId,
    required double lat,
    required double lng,
    int? limit,
    int? offset,
  });
  Future<List<RestaurantProfileModel>> getSavedRestaurants({
    required double lat,
    required double lng,
  });
  Future<void> favoriteRestaurant(String restaurantId);
  Future<void> unfavoriteRestaurant(String restaurantId);
}
