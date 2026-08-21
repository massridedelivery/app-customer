import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:customer_app/features/ride_booking/domain/models/fare_estimation_response.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';

part 'booking_state.freezed.dart';

@freezed
abstract class BookingState with _$BookingState {
  const factory BookingState({
    @Default(false) bool isLoading,
    @Default([]) List<VehicleEstimation> estimations,
    // Online drivers near the pickup, refreshed with the estimate (SCRUM-81).
    @Default(<NearbyDriver>[]) List<NearbyDriver> nearbyDrivers,
    double? distanceKm,
    double? durationMin,
    @Default('CASH') String paymentMethod,
    String? vehicleTypeId,
    String? appliedPromoCode,
    @Default(0.0) double promoDiscount,
    String? encodedPolyline,
    String? activeJobId,
    double? surgeMultiplier,
    String? error,
  }) = _BookingState;
}
