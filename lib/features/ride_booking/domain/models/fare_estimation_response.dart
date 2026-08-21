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
    // Positions of online drivers near the pickup, to plot on the vehicle
    // screen (SCRUM-81). Empty until the backend ships it → nothing is drawn.
    @JsonKey(name: 'nearby_drivers')
    @Default(<NearbyDriver>[])
    List<NearbyDriver> nearbyDrivers,
  }) = _FareEstimationResponse;

  factory FareEstimationResponse.fromJson(Map<String, dynamic> json) =>
      _$FareEstimationResponseFromJson(json);
}

/// A nearby online driver's approximate position (SCRUM-81). No id/name by
/// design (privacy) — just a point to draw a vehicle marker at.
@freezed
abstract class NearbyDriver with _$NearbyDriver {
  const factory NearbyDriver({
    @JsonKey(name: 'lat') @Default(0.0) double lat,
    @JsonKey(name: 'lng') @Default(0.0) double lng,
    @JsonKey(name: 'vehicle_type_id') String? vehicleTypeId,
  }) = _NearbyDriver;

  factory NearbyDriver.fromJson(Map<String, dynamic> json) =>
      _$NearbyDriverFromJson(json);
}
