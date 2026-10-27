import 'package:customer_app/features/ride_booking/domain/models/ride_quote.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_estimation.freezed.dart';
part 'vehicle_estimation.g.dart';

/// A priced vehicle is selectable unless the backend explicitly marks it
/// unavailable. The estimate endpoint may omit the flag (and has used both
/// `available` and `is_available`), so default to available when it's absent —
/// otherwise a re-estimate that drops the field greys out every option.
Object? _readAvailable(Map json, String key) =>
    json['available'] ?? json['is_available'] ?? true;

@freezed
sealed class VehicleEstimation with _$VehicleEstimation {
  const factory VehicleEstimation({
    @JsonKey(name: 'vehicle_type_id') required String vehicleTypeId,
    @JsonKey(name: 'vehicle_type_name') required String vehicleTypeName,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'base_fare') required double baseFare,
    required double discount,
    @JsonKey(name: 'total_fare') required double totalFare,
    // Price before the coupon (total_fare = gross_fare - discount). Optional so
    // older estimate payloads without it still parse.
    @JsonKey(name: 'gross_fare') double? grossFare,
    @JsonKey(name: 'available', readValue: _readAvailable)
    @Default(true)
    bool available,
    @JsonKey(name: 'dropoff_surcharge') @Default(0.0) double dropoffSurcharge,
    @JsonKey(name: 'pickup_surcharge') @Default(0.0) double pickupSurcharge,
    @JsonKey(name: 'surcharge_name') String? surchargeName,
    @JsonKey(name: 'surge_multiplier') @Default(1.0) double surgeMultiplier,
    @JsonKey(name: 'surged_fare') required double surgedFare,
    // Number of available drivers near the pickup for this type (SCRUM-64).
    // Nullable so "field not sent" (null) is distinguishable from "0 drivers".
    @JsonKey(name: 'drivers_nearby') int? driversNearby,
    // After the code AND points (BE §3.1); null on older payloads / guests.
    @JsonKey(name: 'amount_to_pay') double? amountToPay,
    // Unpaid cancellation fees from earlier rides that booking this one adds
    // to what the customer pays; already inside amount_to_pay. Absent → 0.
    @JsonKey(name: 'prior_cancel_fee') @Default(0.0) double priorCancelFee,
    @JsonKey(name: 'promo') Map<String, dynamic>? promoJson,
    @JsonKey(name: 'points') Map<String, dynamic>? pointsJson,
  }) = _VehicleEstimation;

  const VehicleEstimation._();

  /// What the code in the promo box did here (null when none was sent).
  RidePromoQuote? get promo => RidePromoQuote.fromJson(promoJson);

  /// Paying with points on this vehicle.
  RidePointsQuote? get points => RidePointsQuote.fromJson(pointsJson);

  /// What the customer pays — shown on the card and the request button.
  /// The server's amount_to_pay (carried cancellation fee included).
  double get payable => amountToPay ?? totalFare + priorCancelFee;

  /// [payable] for the ride alone, without the carried cancellation fee —
  /// what the fare / discount comparisons on the card are made against.
  double get ridePayable => payable - priorCancelFee;

  factory VehicleEstimation.fromJson(Map<String, dynamic> json) =>
      _$VehicleEstimationFromJson(json);
}
