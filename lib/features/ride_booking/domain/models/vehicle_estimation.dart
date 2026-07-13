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
    @JsonKey(name: 'available', readValue: _readAvailable)
    @Default(true)
    bool available,
    @JsonKey(name: 'dropoff_surcharge') @Default(0.0) double dropoffSurcharge,
    @JsonKey(name: 'pickup_surcharge') @Default(0.0) double pickupSurcharge,
    @JsonKey(name: 'surcharge_name') String? surchargeName,
    @JsonKey(name: 'surge_multiplier') @Default(1.0) double surgeMultiplier,
    @JsonKey(name: 'surged_fare') required double surgedFare,
  }) = _VehicleEstimation;

  factory VehicleEstimation.fromJson(Map<String, dynamic> json) =>
      _$VehicleEstimationFromJson(json);
}
