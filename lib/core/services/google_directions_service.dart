import 'package:customer_app/core/constants/google_config.dart';
import 'package:customer_app/core/utils/polyline_decoder.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Thin wrapper over the Google Directions API, used as a fallback to draw a
/// real road-following route when the backend didn't ship an encoded polyline
/// (otherwise the map falls back to a straight pickup→dropoff line).
///
/// NOTE: the API key ([GoogleConfig.placesApiKey]) must have the **Directions
/// API** enabled in Google Cloud. If it isn't, requests come back
/// `REQUEST_DENIED` and [route] returns an empty list — the caller then keeps
/// the straight-line fallback, so nothing regresses.
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

  /// The road-following route between [origin] and [destination] as decoded
  /// points. Returns an empty list on any failure.
  Future<List<LatLng>> route(LatLng origin, LatLng destination) async {
    final key = GoogleConfig.placesApiKey;
    if (key.isEmpty) return const [];
    try {
      final res = await _dio.get(
        '/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'key': key,
        },
      );
      final data = res.data;
      if (data is! Map) return const [];
      if (data['status'] != 'OK') {
        debugPrint('GoogleDirectionsService: status=${data['status']}');
        return const [];
      }
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return const [];
      final encoded =
          (routes.first as Map)['overview_polyline']?['points'] as String?;
      if (encoded == null || encoded.isEmpty) return const [];
      return PolylineDecoder.decodePolyline(encoded);
    } catch (e) {
      debugPrint('GoogleDirectionsService.route failed: $e');
      return const [];
    }
  }
}
