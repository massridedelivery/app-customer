import 'package:freezed_annotation/freezed_annotation.dart';

part 'messenger_estimate.freezed.dart';
part 'messenger_estimate.g.dart';

/// Response of `POST /api/messenger/customer/estimate`.
/// `total_fare` already nets out the discount (customer pays this).
@freezed
abstract class MessengerEstimate with _$MessengerEstimate {
  const factory MessengerEstimate({
    @JsonKey(name: 'distance_km') @Default(0.0) double distanceKm,
    @JsonKey(name: 'duration_min') @Default(0.0) double durationMin,
    @JsonKey(name: 'base_fare') @Default(0.0) double baseFare,
    @JsonKey(name: 'surcharge') @Default(0.0) double surcharge,
    @JsonKey(name: 'discount') @Default(0.0) double discount,
    @JsonKey(name: 'total_fare') @Default(0.0) double totalFare,
  }) = _MessengerEstimate;

  factory MessengerEstimate.fromJson(Map<String, dynamic> json) =>
      _$MessengerEstimateFromJson(json);
}
