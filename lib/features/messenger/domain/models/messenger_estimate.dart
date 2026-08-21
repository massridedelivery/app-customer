import 'package:freezed_annotation/freezed_annotation.dart';

part 'messenger_estimate.freezed.dart';
part 'messenger_estimate.g.dart';

/// Response of `POST /api/messenger/customer/estimate`.
/// The top-level fare fields describe [deliveryType] (INSTANT when the request
/// didn't specify a mode). `total_fare` already nets out the discount.
/// [serviceLevels] lists every delivery mode the admin currently has enabled —
/// render the mode picker from this array only (never hardcode the modes).
@freezed
abstract class MessengerEstimate with _$MessengerEstimate {
  const factory MessengerEstimate({
    @JsonKey(name: 'distance_km') @Default(0.0) double distanceKm,
    @JsonKey(name: 'duration_min') @Default(0.0) double durationMin,
    @JsonKey(name: 'base_fare') @Default(0.0) double baseFare,
    @JsonKey(name: 'surcharge') @Default(0.0) double surcharge,
    @JsonKey(name: 'discount') @Default(0.0) double discount,
    @JsonKey(name: 'total_fare') @Default(0.0) double totalFare,
    @JsonKey(name: 'delivery_type') String? deliveryType,
    @JsonKey(name: 'service_levels')
    @Default(<MessengerServiceLevel>[])
    List<MessengerServiceLevel> serviceLevels,
  }) = _MessengerEstimate;

  factory MessengerEstimate.fromJson(Map<String, dynamic> json) =>
      _$MessengerEstimateFromJson(json);
}

/// One selectable delivery mode from `estimate.service_levels[]` (SCRUM-71).
/// Server-computed — the app shows [label]/[totalFare]/[deliverBy] as-is.
@freezed
abstract class MessengerServiceLevel with _$MessengerServiceLevel {
  const factory MessengerServiceLevel({
    @JsonKey(name: 'delivery_type') @Default('') String deliveryType,
    @JsonKey(name: 'label') @Default('') String label,
    @JsonKey(name: 'base_fare') @Default(0.0) double baseFare,
    @JsonKey(name: 'size_surcharge') @Default(0.0) double sizeSurcharge,
    @JsonKey(name: 'express_surcharge') @Default(0.0) double expressSurcharge,
    @JsonKey(name: 'discount') @Default(0.0) double discount,
    @JsonKey(name: 'total_fare') @Default(0.0) double totalFare,
    @JsonKey(name: 'pickup_eta_min') int? pickupEtaMin,
    @JsonKey(name: 'deliver_by') String? deliverBy,
  }) = _MessengerServiceLevel;

  factory MessengerServiceLevel.fromJson(Map<String, dynamic> json) =>
      _$MessengerServiceLevelFromJson(json);
}
