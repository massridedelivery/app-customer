import 'package:customer_app/core/constants/google_config.dart';
import 'package:customer_app/core/utils/polyline_decoder.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Shared instance for anyone needing road-following routes / live ETAs.
final googleDirectionsServiceProvider = Provider<GoogleDirectionsService>(
  (ref) => GoogleDirectionsService(),
);

/// One Directions leg: the decoded route plus its travel time and distance.
/// [duration] is traffic-aware when Google returns `duration_in_traffic`.
class DirectionsInfo {
  const DirectionsInfo({
    required this.points,
    required this.duration,
    required this.distanceMeters,
  });

  final List<LatLng> points;
  final Duration duration;
  final int distanceMeters;

  int get minutes => (duration.inSeconds / 60).ceil();
}

/// Thin wrapper over the Google Directions API. Two uses:
///  * [route] — a road-following polyline, used as a fallback when the backend
///    didn't ship one (otherwise the map draws a straight pickup→dropoff line).
///  * [routeInfo] — the same route plus a traffic-aware travel time, used to
///    show a live "arrives in ~N min" ETA (driver's location → target).
///
/// NOTE: the API key ([GoogleConfig.placesApiKey]) must have the **Directions
/// API** enabled in Google Cloud. If it isn't, requests come back
/// `REQUEST_DENIED`, [routeInfo] returns null and [route] returns an empty
/// list — callers keep their straight-line / hidden-ETA fallbacks, so nothing
/// regresses.
class GoogleDirectionsService {
  final Dio _dio;

  GoogleDirectionsService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://maps.googleapis.com',
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
            ),
          );

  /// The road-following route + traffic-aware travel time between [origin] and
  /// [destination]. Returns null on any failure.
  Future<DirectionsInfo?> routeInfo(LatLng origin, LatLng destination) async {
    final key = GoogleConfig.placesApiKey;
    if (key.isEmpty) return null;
    try {
      final res = await _dio.get(
        '/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          // Enables `duration_in_traffic` — the live, traffic-aware ETA that
          // apps like Grab/LINE MAN show.
          'departure_time': 'now',
          'key': key,
        },
      );
      final data = res.data;
      if (data is! Map || data['status'] != 'OK') {
        debugPrint(
          'GoogleDirectionsService.routeInfo: status='
          '${data is Map ? data['status'] : 'n/a'}',
        );
        return null;
      }
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final route0 = routes.first as Map;
      final legs = route0['legs'];
      final leg = (legs is List && legs.isNotEmpty)
          ? legs.first as Map
          : const <String, dynamic>{};
      final durationSec =
          (leg['duration_in_traffic']?['value'] ?? leg['duration']?['value'])
              as int?;
      final distanceM = leg['distance']?['value'] as int?;
      final encoded = route0['overview_polyline']?['points'] as String?;
      final points = (encoded == null || encoded.isEmpty)
          ? const <LatLng>[]
          : PolylineDecoder.decodePolyline(encoded);
      return DirectionsInfo(
        points: points,
        duration: Duration(seconds: durationSec ?? 0),
        distanceMeters: distanceM ?? 0,
      );
    } catch (e) {
      debugPrint('GoogleDirectionsService.routeInfo failed: $e');
      return null;
    }
  }

  /// The road-following route between [origin] and [destination] as decoded
  /// points. Returns an empty list on any failure.
  Future<List<LatLng>> route(LatLng origin, LatLng destination) async =>
      (await routeInfo(origin, destination))?.points ?? const [];
}
