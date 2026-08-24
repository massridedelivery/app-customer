import 'dart:math';

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
  /// Groups every autocomplete keystroke + the final details lookup of one
  /// search into a single Google billing session (SCRUM-74). Minted lazily on
  /// the first keystroke of a session and retired once a place is resolved or
  /// the field is cleared, so the next search starts a fresh session.
  String? _sessionToken;

  @override
  PlaceSearchState build() => const PlaceSearchState();

  String _ensureSessionToken() => _sessionToken ??= _newSessionToken();

  static String _newSessionToken() {
    final rand = Random();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final suffix = List.generate(
      8,
      (_) => rand.nextInt(16).toRadixString(16),
    ).join();
    return '$ts-$suffix';
  }

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
      final predictions = await ref.read(searchPlacesUseCaseProvider).call(
            trimmed,
            lat: location?.latitude,
            lng: location?.longitude,
            sessionToken: _ensureSessionToken(),
          );
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
      final place = await ref.read(getPlaceDetailsUseCaseProvider).call(
            prediction.placeId,
            sessionToken: _sessionToken,
          );
      // Selecting a place closes the session — the next search bills fresh.
      _sessionToken = null;
      return place;
    } catch (e) {
      debugPrint('Failed to resolve place details: $e');
      return null;
    }
  }

  void clear() {
    _sessionToken = null;
    state = const PlaceSearchState();
  }
}
