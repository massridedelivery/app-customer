import 'package:dio/dio.dart';
import 'package:customer_app/core/constants/google_config.dart';
import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/models/place_prediction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final googlePlacesServiceProvider = Provider<GooglePlacesService>((ref) {
  return GooglePlacesService();
});

/// Thin client for the Google Places web service (Autocomplete + Details).
///
/// Uses its own [Dio] instance so it never inherits the BFF base URL or the
/// `Authorization` interceptor from [ApiService] — Google rejects requests
/// that carry an unexpected bearer token.
class GooglePlacesService {
  final Dio _dio;

  GooglePlacesService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: GoogleConfig.placesBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  /// Returns autocomplete predictions for [input], biased around [lat]/[lng]
  /// when provided. [sessionToken] groups Autocomplete + Details calls for
  /// billing and should be the same value until a prediction is selected.
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    double? lat,
    double? lng,
    String? sessionToken,
  }) async {
    _ensureConfigured();
    try {
      final response = await _dio.get(
        '/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': GoogleConfig.placesApiKey,
          'language': GoogleConfig.language,
          'components': GoogleConfig.components,
          if (lat != null && lng != null) 'location': '$lat,$lng',
          if (lat != null && lng != null) 'radius': 30000,
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );

      final data = response.data as Map<String, dynamic>;
      _checkStatus(data);

      final predictions = (data['predictions'] as List<dynamic>? ?? []);
      return predictions
          .map((e) => _mapPrediction(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e, 'ค้นหาสถานที่ไม่สำเร็จ'));
    }
  }

  /// Resolves a [placeId] into a full [Place] with coordinates.
  Future<Place> placeDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    _ensureConfigured();
    try {
      final response = await _dio.get(
        '/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': GoogleConfig.placesApiKey,
          'language': GoogleConfig.language,
          'fields': 'place_id,name,formatted_address,geometry/location',
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );

      final data = response.data as Map<String, dynamic>;
      _checkStatus(data);

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) {
        throw ServerException('ไม่พบข้อมูลสถานที่');
      }
      return _mapDetails(result);
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e, 'ดึงข้อมูลสถานที่ไม่สำเร็จ'));
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _ensureConfigured() {
    if (!GoogleConfig.isConfigured) {
      throw ServerException(
        'ยังไม่ได้ตั้งค่า Google Places API key (google_config.dart)',
      );
    }
  }

  /// Google returns HTTP 200 even for logical errors; the real state is in the
  /// `status` field.
  void _checkStatus(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    if (status == 'OK' || status == 'ZERO_RESULTS') return;
    final msg = data['error_message'] as String?;
    throw ServerException(msg ?? 'Google Places error: $status');
  }

  PlacePrediction _mapPrediction(Map<String, dynamic> json) {
    final structured =
        json['structured_formatting'] as Map<String, dynamic>? ?? const {};
    return PlacePrediction(
      placeId: json['place_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      mainText: structured['main_text']?.toString() ??
          json['description']?.toString() ??
          '',
      secondaryText: structured['secondary_text']?.toString() ?? '',
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
    );
  }

  Place _mapDetails(Map<String, dynamic> json) {
    final location = (json['geometry']
            as Map<String, dynamic>?)?['location'] as Map<String, dynamic>?;
    return Place(
      placeId: json['place_id']?.toString(),
      name: json['name']?.toString() ?? '',
      address: json['formatted_address']?.toString(),
      lat: (location?['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location?['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String _dioMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error_message'] is String) {
      return data['error_message'] as String;
    }
    return fallback;
  }
}
