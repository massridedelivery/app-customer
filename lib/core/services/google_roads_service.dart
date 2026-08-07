import 'package:customer_app/core/constants/google_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final googleRoadsServiceProvider = Provider<GoogleRoadsService>((ref) {
  return GoogleRoadsService();
});

/// Snaps a coordinate to the nearest drivable road via the Google Roads API
/// (`nearestRoads`). Used so a pickup/dropoff the customer pinned inside a
/// building lands on a road the driver can actually reach.
///
/// Best-effort: any failure returns null and the caller keeps the original
/// point. In particular the Roads API must be enabled on the platform's Google
/// key — it currently is on Android but NOT on the iOS Places key, where this
/// returns null (a 403) until that key is granted Roads API access.
class GoogleRoadsService {
  final Dio _dio;

  GoogleRoadsService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://roads.googleapis.com',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  Future<LatLng?> nearestRoad(LatLng point) async {
    final key = GoogleConfig.placesApiKey;
    if (key.isEmpty) return null;
    try {
      final response = await _dio.get(
        '/v1/nearestRoads',
        queryParameters: {
          'points': '${point.latitude},${point.longitude}',
          'key': key,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final snapped = data['snappedPoints'] as List<dynamic>?;
      if (snapped == null || snapped.isEmpty) return null;
      final location =
          (snapped.first as Map<String, dynamic>)['location']
              as Map<String, dynamic>?;
      final lat = (location?['latitude'] as num?)?.toDouble();
      final lng = (location?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    } catch (_) {
      // Network error, or the API isn't enabled on this key (403): fall back to
      // the original point so selection still works.
      return null;
    }
  }
}
