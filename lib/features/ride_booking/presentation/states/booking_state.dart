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
    // Why the applied code took ฿0 off (localized, from /promos/validate).
    String? promoRejectReason,
    String? encodedPolyline,
    String? activeJobId,
    double? surgeMultiplier,
    String? error,
    // Paying with points: off every time the screen opens. pointsToUse null
    // with usePoints = "as many as allowed"; a number = that exact amount.
    @Default(false) bool usePoints,
    int? pointsToUse,
    // The admin switched points off mid-booking (POINTS_DISABLED): hide the row.
    @Default(false) bool pointsDisabled,
    // Set when the chosen amount had to come down to a new maximum, so the
    // screen can say "ปรับเป็น N คะแนน" once.
    int? pointsAdjustedTo,
    // A booking went through without the code's discount (it stopped
    // applying in between) — tell the customer once.
    @Default(false) bool promoDroppedOnBooking,
    // When the shown estimate was fetched: a stale one is refreshed before
    // booking.
    DateTime? estimatedAt,
  }) = _BookingState;
}
