import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/models/place_prediction.dart';
import 'package:customer_app/features/home/domain/usecases/get_place_details_usecase_impl.dart';
import 'package:customer_app/features/home/domain/usecases/search_places_usecase_impl.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/place_search_state.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_search_controller.g.dart';

/// Owns the autocomplete results for the place-search screens. Isolated from
/// [HomeController] so typing doesn't mutate the shared home state.
@riverpod
class PlaceSearchController extends _$PlaceSearchController {
  @override
  PlaceSearchState build() => const PlaceSearchState();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const PlaceSearchState();
      return;
    }

    state = state.copyWith(
      query: trimmed,
      isSearching: true,
      hasError: false,
    );
    try {
      // Read the current location once, without subscribing to home state.
      final location = ref.read(homeControllerProvider).currentLocation;
      final predictions = await ref
          .read(searchPlacesUseCaseProvider)
          .call(trimmed, lat: location?.latitude, lng: location?.longitude);
      state = state.copyWith(results: predictions, isSearching: false);
    } catch (e) {
      debugPrint('Search failed: $e');
      state = state.copyWith(
        results: const [],
        isSearching: false,
        hasError: true,
      );
    }
  }

  /// Re-runs the last query — used by the error state's retry action.
  Future<void> retry() => search(state.query);

  /// Resolves a selected autocomplete [prediction] into a full [Place] with
  /// coordinates via a Place Details lookup. Returns null on failure.
  Future<Place?> resolveDetails(PlacePrediction prediction) async {
    try {
      return await ref
          .read(getPlaceDetailsUseCaseProvider)
          .call(prediction.placeId);
    } catch (e) {
      debugPrint('Failed to resolve place details: $e');
      return null;
    }
  }

  void clear() => state = const PlaceSearchState();
}
