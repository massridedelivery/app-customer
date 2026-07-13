import 'package:freezed_annotation/freezed_annotation.dart';

import 'vehicle_estimation.dart';

part 'fare_estimation_response.freezed.dart';
part 'fare_estimation_response.g.dart';

/// The route's encoded polyline has shipped under a few different keys
/// (`waypoint`, `polyline`, `encoded_polyline`, `overview_polyline`). Accept
/// any of them so the booking map draws the real road route instead of falling
/// back to a straight pickup→dropoff line.
Object? _readWaypoint(Map json, String key) =>
    json['waypoint'] ??
    json['polyline'] ??
    json['encoded_polyline'] ??
    json['overview_polyline'];

@freezed
abstract class FareEstimationResponse with _$FareEstimationResponse {
  const factory FareEstimationResponse({
    @JsonKey(name: 'distance_km') required double distanceKm,
    @JsonKey(name: 'duration_min') required int durationMin,
    required List<VehicleEstimation> estimations,
    @JsonKey(name: 'surge_multiplier') @Default(1.0) double surgeMultiplier,
    @JsonKey(name: 'waypoint', readValue: _readWaypoint) String? waypoint,
  }) = _FareEstimationResponse;

  factory FareEstimationResponse.fromJson(Map<String, dynamic> json) =>
      _$FareEstimationResponseFromJson(json);
}
