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
    // Estimated arrival time at the current target (pickup before PICKED_UP,
    // dropoff after). The backend computes it ONCE per phase (traffic-aware) and
    // pushes it on the driver-location socket; the client derives both the
    // "อีก N นาที" countdown and the "ถึงประมาณ HH:MM" clock from it locally, so
    // no routing API is called while the ride runs. Null until the backend sends
    // it.
    DateTime? etaArriveAt,
    double? fare,
    double? discount,
    // Fee the customer would be charged if they cancel now (SCRUM-65).
    double? estimatedCancelFee,
    // Fee actually charged after a cancellation (from the cancel response).
    double? chargedCancelFee,
    @Default('PENDING')
    String? jobStatus, // PENDING, ACCEPTED, PICKED_UP, COMPLETED, CANCELLED
    String? error,
    DriverProfileModel? driverProfile,
  }) = _LiveRideState;
}
