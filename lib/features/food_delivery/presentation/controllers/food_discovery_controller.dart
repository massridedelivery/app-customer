import 'package:customer_app/features/food_delivery/data/repositories/food_discovery_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_discovery_controller.g.dart';

@Riverpod(keepAlive: true)
class FoodDiscovery extends _$FoodDiscovery {
  @override
  FutureOr<HomeResponseModel> build() async {
    // Select only the location object to prevent unnecessary API reloads when
    // other HomeController states change (like mapCenter, searchResults, etc.).
    final location = ref.watch(
      homeControllerProvider.select(
        (state) =>
            state.foodLocation ??
            state.pickupLocation ??
            state.currentLocation,
      ),
    );
    final lat = location?.latitude ?? 13.7563;
    final lng = location?.longitude ?? 100.5018;

    final repo = ref.watch(foodDiscoveryRepositoryProvider);
    return await repo.getHomeFeed(lat: lat, lng: lng);
  }

  Future<void> refreshFeed() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final homeState = ref.read(homeControllerProvider);
      final location =
          homeState.foodLocation ??
          homeState.pickupLocation ??
          homeState.currentLocation;
      final lat = location?.latitude ?? 13.7563;
      final lng = location?.longitude ?? 100.5018;

      final repo = ref.read(foodDiscoveryRepositoryProvider);
      return await repo.getHomeFeed(lat: lat, lng: lng);
    });
  }
}
