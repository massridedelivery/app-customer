import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_places_state.freezed.dart';

@freezed
abstract class SavedPlacesState with _$SavedPlacesState {
  const factory SavedPlacesState({
    required AsyncValue<List<Place>> places,
    @Default(false) bool isDeleting,
    String? error,
  }) = _SavedPlacesState;
}
