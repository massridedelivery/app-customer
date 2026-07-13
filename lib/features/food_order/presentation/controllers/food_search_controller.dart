import 'package:customer_app/features/food_delivery/data/repositories/food_discovery_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_search_controller.g.dart';

// State definition for search
class FoodSearchState {
  final bool isLoading;
  final String query;
  final List<RestaurantProfileModel> restaurantResults;
  final String? error;

  FoodSearchState({
    required this.isLoading,
    required this.query,
    required this.restaurantResults,
    this.error,
  });

  factory FoodSearchState.initial() {
    return FoodSearchState(
      isLoading: false,
      query: '',
      restaurantResults: [],
    );
  }

  FoodSearchState copyWith({
    bool? isLoading,
    String? query,
    List<RestaurantProfileModel>? restaurantResults,
    String? error,
  }) {
    return FoodSearchState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      restaurantResults: restaurantResults ?? this.restaurantResults,
      error: error ?? this.error,
    );
  }
}

@riverpod
class FoodSearchController extends _$FoodSearchController {
  @override
  FoodSearchState build() {
    return FoodSearchState.initial();
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true, error: null);

    if (query.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        restaurantResults: [],
      );
      return;
    }

    try {
      final homeState = ref.read(homeControllerProvider);
      final location = homeState.foodLocation ??
          homeState.pickupLocation ??
          homeState.currentLocation;
      final lat = location?.latitude ?? 13.7563;
      final lng = location?.longitude ?? 100.5018;

      final repo = ref.read(foodDiscoveryRepositoryProvider);
      final results = await repo.searchRestaurants(
        query: query,
        lat: lat,
        lng: lng,
      );

      state = state.copyWith(
        isLoading: false,
        restaurantResults: results,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = FoodSearchState.initial();
  }
}
