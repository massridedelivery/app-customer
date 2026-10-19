import 'package:customer_app/features/home/domain/models/place_prediction.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_search_state.freezed.dart';

/// Transient state for the place-search text field, kept separate from
/// [HomeState] so per-keystroke updates don't rebuild every widget that
/// watches the shared home controller (map screens, ride landing, etc.).
@freezed
abstract class PlaceSearchState with _$PlaceSearchState {
  const factory PlaceSearchState({
    @Default([]) List<PlacePrediction> results,
    @Default(false) bool isSearching,
    @Default(false) bool hasError,

    /// Search can't run right now (proxy 429 / 502 / 503, or offline / timed
    /// out) — show "try again later", not "no places found".
    @Default(false) bool isUnavailable,

    /// A search for [query] has completed, so empty [results] really means
    /// nothing was found (vs. not searched yet).
    @Default(false) bool hasSearched,
    @Default('') String query,
  }) = _PlaceSearchState;
}
