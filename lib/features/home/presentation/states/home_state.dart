import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/features/home/domain/models/place.dart';

part 'home_state.freezed.dart';

enum RideSelectionMode { none, pickup, dropoff, savePlace, food, messengerDropoff }

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(false) bool isLoading,
    @Default(RideSelectionMode.none) RideSelectionMode selectionMode,
    @Default(false) bool isSearching,
    LatLng? currentLocation,
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    LatLng? foodLocation,
    LatLng? mapCenter,
    String? pickupAddress,
    String? dropoffAddress,
    String? foodAddress,
    String? tempAddress,
    LatLng? tempLocation,
    @Default([]) List<Place> savedPlaces,
    @Default([]) List<Place> recentPlaces,
    String? error,
  }) = _HomeState;
}
