import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// How far (in metres) a route's first/last point may sit from the pickup /
/// dropoff pin and still count as a route *for those pins*. Generous enough to
/// cover a road-snapped start or end (a pin dropped in a car park or on the
/// far carriageway), tight enough to reject a route that was computed for a
/// different point — e.g. a backend route seen running on past the dropoff pin
/// along ทล.106.
const double kRouteEndpointToleranceMeters = 200;

/// Great-circle distance between [a] and [b] in metres (haversine).
double distanceMeters(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final sinLat = math.sin(dLat / 2);
  final sinLng = math.sin(dLng / 2);
  final h =
      sinLat * sinLat +
      math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) * sinLng * sinLng;
  return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(h)));
}

/// Whether [route] starts at [pickup] and ends at [dropoff], each within
/// [toleranceMeters]. An empty route never matches.
bool routeMatchesEndpoints(
  List<LatLng> route,
  LatLng pickup,
  LatLng dropoff, {
  double toleranceMeters = kRouteEndpointToleranceMeters,
}) {
  if (route.isEmpty) return false;
  return distanceMeters(route.first, pickup) <= toleranceMeters &&
      distanceMeters(route.last, dropoff) <= toleranceMeters;
}

/// [route] with [pickup] prepended and [dropoff] appended (unless it already
/// starts / ends exactly there), so the drawn line touches both pins instead
/// of stopping short at the road-snapped ends. Only call this for a route that
/// [routeMatchesEndpoints] — stitching a far-off end would draw a straight
/// segment across the map.
List<LatLng> joinRouteToPins(
  List<LatLng> route,
  LatLng pickup,
  LatLng dropoff,
) {
  if (route.isEmpty) return [pickup, dropoff];
  return [
    if (route.first != pickup) pickup,
    ...route,
    if (route.last != dropoff) dropoff,
  ];
}
