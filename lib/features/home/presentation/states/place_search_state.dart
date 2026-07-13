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
  }) = _PlaceSearchState;
}
