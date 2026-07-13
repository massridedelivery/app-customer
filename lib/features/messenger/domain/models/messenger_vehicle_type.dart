import 'package:freezed_annotation/freezed_annotation.dart';

part 'messenger_vehicle_type.freezed.dart';
part 'messenger_vehicle_type.g.dart';

/// Messenger vehicle from `GET /api/vehicle-types`
/// (filtered to `vehicle_class == "messenger"`). Its [sizeTiers] drive the
/// S/M/L package picker; use [id] as `vehicle_type_id` in estimate/create.
@freezed
abstract class MessengerVehicleType with _$MessengerVehicleType {
  const MessengerVehicleType._();

  const factory MessengerVehicleType({
    @JsonKey(name: 'id') @Default('') String id,
    @JsonKey(name: 'name') @Default('') String name,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @JsonKey(name: 'vehicle_class') @Default('') String vehicleClass,
    @JsonKey(name: 'base_fare') @Default(0.0) double baseFare,
    @JsonKey(name: 'price_per_km') @Default(0.0) double pricePerKm,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'size_tiers') @Default([]) List<MessengerSizeTier> sizeTiers,
  }) = _MessengerVehicleType;

  factory MessengerVehicleType.fromJson(Map<String, dynamic> json) =>
      _$MessengerVehicleTypeFromJson(json);

  bool get isMessenger => vehicleClass.toLowerCase() == 'messenger';
}

/// One S/M/L box limit row of a messenger vehicle.
@freezed
abstract class MessengerSizeTier with _$MessengerSizeTier {
  const factory MessengerSizeTier({
    @JsonKey(name: 'tier') @Default('') String tier,
    @JsonKey(name: 'max_length_cm') @Default(0) int maxLengthCm,
    @JsonKey(name: 'max_width_cm') @Default(0) int maxWidthCm,
    @JsonKey(name: 'max_height_cm') @Default(0) int maxHeightCm,
    @JsonKey(name: 'max_weight_kg') @Default(0) int maxWeightKg,
    @JsonKey(name: 'surcharge_thb') @Default(0) int surchargeThb,
  }) = _MessengerSizeTier;

  factory MessengerSizeTier.fromJson(Map<String, dynamic> json) =>
      _$MessengerSizeTierFromJson(json);
}
