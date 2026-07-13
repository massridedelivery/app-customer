import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/presentation/states/restaurant_detail_state.dart';
import 'package:customer_app/features/food_delivery/data/repositories/food_discovery_repository_impl.dart';
import 'package:customer_app/features/food_delivery/presentation/controllers/food_discovery_controller.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'restaurant_detail_controller.g.dart';

@riverpod
class RestaurantDetail extends _$RestaurantDetail {
  @override
  RestaurantDetailState build(String restaurantId) {
    Future.microtask(() => _load(restaurantId));
    return const RestaurantDetailState();
  }

  Future<void> _load(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final homeState = ref.read(homeControllerProvider);
      final location =
          homeState.foodLocation ??
          homeState.pickupLocation ??
          homeState.currentLocation;
      final lat = location?.latitude ?? 13.7563;
      final lng = location?.longitude ?? 100.5018;

      final repo = ref.read(foodOrderRepositoryProvider);
      var profile = await repo.getRestaurantProfile(id);

      // Check if saved
      try {
        final discoveryRepo = ref.read(foodDiscoveryRepositoryProvider);
        final savedRestaurants = await discoveryRepo.getSavedRestaurants(
          lat: lat,
          lng: lng,
        );
        final isSaved = savedRestaurants.any(
          (r) => r.id == id || r.id == profile.id,
        );
        profile = profile.copyWith(isSaved: isSaved);
      } catch (_) {
        // Fallback to whatever the API returned, or false by default
      }

      final menu = await repo.getRestaurantMenu(id);
      
      List<PromoModel> promos = [];
      try {
        promos = await repo.getPromoContext(
          appliesTo: 'FOOD',
          merchantId: id,
        );
      } catch (_) {
        // Fallback or ignore if the promo api fails, ensuring menu load isn't completely blocked
      }

      state = state.copyWith(
        isLoading: false,
        restaurant: profile,
        menuCategories: menu,
        promos: promos,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleSave() async {
    final restaurant = state.restaurant;
    if (restaurant == null) return;

    final originalIsSaved = restaurant.isSaved;
    final targetSaved = !originalIsSaved;

    // Optimistically update local state
    state = state.copyWith(
      restaurant: restaurant.copyWith(isSaved: targetSaved),
    );

    try {
      final discoveryRepo = ref.read(foodDiscoveryRepositoryProvider);
      if (targetSaved) {
        await discoveryRepo.favoriteRestaurant(restaurant.id);
      } else {
        await discoveryRepo.unfavoriteRestaurant(restaurant.id);
      }

      // Invalidate the discovery feed to sync home screen
      ref.invalidate(foodDiscoveryProvider);
    } catch (e) {
      // Revert state on error
      state = state.copyWith(
        restaurant: restaurant.copyWith(isSaved: originalIsSaved),
      );
    }
  }

  Future<void> retry(String id) async {
    await _load(id);
  }
}
