import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/models/place_prediction.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final placesProxyServiceProvider = Provider<PlacesProxyService>((ref) {
  // Reuse ApiService's Dio so proxy calls carry the BFF base URL + auth.
  return PlacesProxyService(ref.watch(apiServiceProvider).dio);
});

/// Places autocomplete + details via our backend proxy (SCRUM-74):
/// `GET /api/places/autocomplete` and `GET /api/places/details`. The BFF holds
/// the Google key server-side, so the app ships no key. Calls go through
/// [ApiService] (authenticated, BFF base URL).
///
/// [sessionToken] must be one value per search session — the same token for
/// every autocomplete keystroke and the final details lookup — so Google bills
/// the session as one unit; the caller ([PlaceSearchController]) owns it.
///
/// Unlike Google's web service (HTTP 200 + a `status` field), the proxy returns
/// real HTTP status codes: 400 bad input, 404 not found, 502 upstream/quota,
/// 503 key not configured yet — mapped to Thai here.
class PlacesProxyService {
  final Dio _dio;

  PlacesProxyService(this._dio);

  Future<List<PlacePrediction>> autocomplete(
    String input, {
    double? lat,
    double? lng,
    String? sessionToken,
  }) async {
    try {
      final response = await _dio.get(
        '/api/places/autocomplete',
        queryParameters: {
          'input': input,
          'session_token': ?sessionToken,
          if (lat != null && lng != null) 'lat': lat,
          if (lat != null && lng != null) 'lng': lng,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final list = _predictionsList(data);
      return list
          .map((e) => _mapPrediction(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_message(e, 'ค้นหาสถานที่ไม่สำเร็จ'));
    }
  }

  Future<Place> placeDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    try {
      final response = await _dio.get(
        '/api/places/details',
        queryParameters: {
          'place_id': placeId,
          'session_token': ?sessionToken,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final result = _detailsResult(data);
      if (result == null) throw ServerException('ไม่พบข้อมูลสถานที่');
      return _mapDetails(result);
    } on DioException catch (e) {
      throw ServerException(_message(e, 'ดึงข้อมูลสถานที่ไม่สำเร็จ'));
    }
  }

  // ── parsing ─────────────────────────────────────────────────────────────
  // Tolerant of a Google-native passthrough ({predictions}/{result}) or a
  // normalised envelope ({data}) so a small BE shape change doesn't break search.

  List<dynamic> _predictionsList(Map<String, dynamic> data) {
    final p = data['predictions'] ?? data['data'] ?? data['results'];
    return p is List ? p : const [];
  }

  Map<String, dynamic>? _detailsResult(Map<String, dynamic> data) {
    final r = data['result'] ?? data['data'] ?? data;
    return r is Map<String, dynamic> ? r : null;
  }

  PlacePrediction _mapPrediction(Map<String, dynamic> json) {
    final structured =
        json['structured_formatting'] as Map<String, dynamic>? ?? const {};
    return PlacePrediction(
      placeId: json['place_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      mainText: structured['main_text']?.toString() ??
          json['main_text']?.toString() ??
          json['description']?.toString() ??
          '',
      secondaryText: structured['secondary_text']?.toString() ??
          json['secondary_text']?.toString() ??
          '',
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
    );
  }

  Place _mapDetails(Map<String, dynamic> json) {
    final location = (json['geometry']
            as Map<String, dynamic>?)?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble() ??
        (json['lat'] as num?)?.toDouble() ??
        0.0;
    final lng = (location?['lng'] as num?)?.toDouble() ??
        (json['lng'] as num?)?.toDouble() ??
        0.0;
    return Place(
      placeId: json['place_id']?.toString(),
      name: json['name']?.toString() ?? '',
      address: (json['formatted_address'] ?? json['address'])?.toString(),
      lat: lat,
      lng: lng,
    );
  }

  String _message(DioException e, String fallback) {
    switch (e.response?.statusCode) {
      case 400:
        return 'คำค้นหาสั้นหรือไม่ถูกต้อง';
      case 404:
        return 'ไม่พบสถานที่';
      case 502:
        return 'ค้นหาสถานที่ไม่สำเร็จ ระบบแผนที่ขัดข้องชั่วคราว';
      case 503:
        return 'บริการค้นหาสถานที่ยังไม่พร้อมใช้งาน กรุณาลองใหม่ภายหลัง';
      default:
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          return data['message'] as String;
        }
        return fallback;
    }
  }
}
