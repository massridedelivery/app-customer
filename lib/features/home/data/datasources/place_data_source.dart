import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/core/services/google_places_service.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/models/place_prediction.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_data_source.g.dart';

abstract class PlaceDataSource {
  /// Google Places Autocomplete predictions.
  Future<List<PlacePrediction>> autocomplete(
    String query, {
    double? lat,
    double? lng,
  });

  /// Google Place Details for a prediction's [placeId].
  Future<Place> getPlaceDetails(String placeId);

  /// Recently used places (from the BFF).
  Future<List<dynamic>> getRecentPlaces();

  Future<List<dynamic>> getSavedPlaces();

  Future<Map<String, dynamic>> addSavedPlace({
    required String name,
    required double lat,
    required double lng,
    String? address,
    bool? isDefault,
    String? id,
    String? note,
    String? phoneNumber,
  });

  Future<Map<String, dynamic>> setDefaultPlace(String id);

  Future<void> deleteSavedPlace(String id);

  Future<Map<String, dynamic>> getDefaultPlace();
}

@riverpod
PlaceDataSourceImpl placeDataSource(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  final places = ref.watch(googlePlacesServiceProvider);
  return PlaceDataSourceImpl(apiService, places);
}

class PlaceDataSourceImpl implements PlaceDataSource {
  final ApiService _apiService;
  final GooglePlacesService _places;

  PlaceDataSourceImpl(this._apiService, this._places);

  @override
  Future<List<PlacePrediction>> autocomplete(
    String query, {
    double? lat,
    double? lng,
  }) {
    return _places.autocomplete(query, lat: lat, lng: lng);
  }

  @override
  Future<Place> getPlaceDetails(String placeId) {
    return _places.placeDetails(placeId);
  }

  @override
  Future<List<dynamic>> getRecentPlaces() async {
    // Recent/frequent destinations. The path is `/places/frequent` per plan.md
    // ("Frequent Travel: GET /api/customer/places/frequent"); the earlier
    // `/places/recent` guess hit 405 because the BFF matched it as
    // `/places/{id}` (which only serves POST/DELETE).
    try {
      final response = await _apiService.dio.get(
        '/api/customer/places/frequent',
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      // Recent places are a non-critical convenience list. If the endpoint is
      // unavailable (404) or method-mismatched while the BFF is still settling
      // (405), degrade to an empty list instead of breaking the home screen.
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) return const [];
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getSavedPlaces() async {
    final response = await _apiService.dio.get('/api/customer/places');
    return response.data as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> addSavedPlace({
    required String name,
    required double lat,
    required double lng,
    String? address,
    bool? isDefault,
    String? id,
    String? note,
    String? phoneNumber,
  }) async {
    final response = await _apiService.dio.post(
      '/api/customer/places',
      data: {
        'id': ?id,
        'name': name,
        'address': ?address,
        'lat': lat,
        'lng': lng,
        'note': ?note,
        'is_default': ?isDefault,
        'phone_number': ?phoneNumber,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> setDefaultPlace(String id) async {
    final response = await _apiService.dio.post(
      '/api/customer/places/$id/default',
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> deleteSavedPlace(String id) async {
    await _apiService.dio.delete('/api/customer/places/$id');
  }

  @override
  Future<Map<String, dynamic>> getDefaultPlace() async {
    final response = await _apiService.dio.get(
      '/api/customer/places/default',
    );
    return response.data as Map<String, dynamic>;
  }
}
