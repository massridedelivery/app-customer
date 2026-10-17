import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/utils/polyline_decoder.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final directionsServiceProvider = Provider<DirectionsService>((ref) {
  // Reuse ApiService's Dio so calls carry the BFF base URL + auth (and its
  // 401 → refresh-and-retry interceptor).
  return DirectionsService(ref.watch(apiServiceProvider).dio);
});

/// Road-following route via our backend (`GET /api/directions`, dev106), used
/// as a fallback when the fare estimate didn't ship an encoded polyline. The
/// BE proxies Google Directions server-side, so the app ships no key.
///
/// Same params/shape as Google's Directions API, plus flat `polyline` /
/// `distance_m` / `duration_s`. `estimated: true` means the routing backend
/// was down and the polyline is a straight-line approximation — still fine to
/// draw; we never show a time from here (the fare estimate owns distance/ETA).
///
/// Any failure (400 bad coordinates, 502 upstream, network) returns an empty
/// list, so the map keeps its straight pickup→dropoff line.
class DirectionsService {
  final Dio _dio;

  DirectionsService(this._dio);

  Future<List<LatLng>> route(LatLng origin, LatLng destination) async {
    try {
      final res = await _dio.get(
        '/api/directions',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
        },
      );
      final encoded = encodedPolylineOf(res.data);
      if (encoded == null || encoded.isEmpty) return const [];
      return PolylineDecoder.decodePolyline(encoded);
    } catch (e) {
      debugPrint('DirectionsService.route failed: $e');
      return const [];
    }
  }

  /// The encoded polyline from a `/api/directions` body: the flat `polyline`
  /// first, then Google's `routes[0].overview_polyline.points`.
  @visibleForTesting
  static String? encodedPolylineOf(Object? data) {
    if (data is! Map) return null;
    final flat = data['polyline'];
    if (flat is String && flat.isNotEmpty) return flat;
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) return null;
    final overview = (routes.first as Map)['overview_polyline'];
    final points = overview is Map ? overview['points'] : null;
    return points is String ? points : null;
  }
}
