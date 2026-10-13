import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/features/home/domain/models/place.dart';

part 'home_state.freezed.dart';

enum RideSelectionMode { none, pickup, dropoff, savePlace, food, messengerDropoff }

/// Outcome of the device-location bootstrap. Kept separate from
/// [HomeState.pickupAddress] so a failure is never shown (or sent to the
/// backend) as if it were an address.
enum LocationAccess {
  /// Not resolved yet.
  unknown,
  granted,

  /// Denied this time — asking again can still show the system prompt.
  denied,

  /// Permanently denied — only the app's system Settings can re-enable it.
  deniedForever,

  /// Location services (GPS) are switched off on the device.
  serviceDisabled,

  /// Permission granted but the fix itself failed.
  unavailable,
}

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
    // Bumped whenever a snap-to-road moves [mapCenter] off the user's raw pin;
    // the selection screens watch it to animate the camera onto the road.
    @Default(0) int mapSnapNonce,
    @Default([]) List<Place> savedPlaces,
    @Default([]) List<Place> recentPlaces,
    @Default(LocationAccess.unknown) LocationAccess locationAccess,
    String? error,
  }) = _HomeState;
}
