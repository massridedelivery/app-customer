import 'package:customer_app/features/live_ride/domain/models/driver_profile_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'live_ride_state.freezed.dart';

@freezed
abstract class LiveRideState with _$LiveRideState {
  const factory LiveRideState({
    @Default(false) bool isLoading,
    String? jobId,
    String? driverId,
    String? driverName,
    String? vehiclePlate,
    String? vehicleColor,
    String? vehicleType,
    double? driverRating,
    LatLng? driverLocation,
    double? fare,
    double? discount,
    @Default('PENDING')
    String? jobStatus, // PENDING, ACCEPTED, PICKED_UP, COMPLETED, CANCELLED
    String? error,
    DriverProfileModel? driverProfile,
  }) = _LiveRideState;
}
