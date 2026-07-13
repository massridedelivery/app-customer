import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/models/place_prediction.dart';

abstract class PlaceRepository {
  /// Google Places Autocomplete predictions for [query].
  Future<List<PlacePrediction>> autocomplete(
    String query, {
    double? lat,
    double? lng,
  });

  /// Resolves a prediction [placeId] into a full [Place] with coordinates.
  Future<Place> getPlaceDetails(String placeId);

  /// Recently used places.
  Future<List<Place>> getRecentPlaces();

  Future<List<Place>> getSavedPlaces();

  Future<void> addSavedPlace({
    required String name,
    required double lat,
    required double lng,
    String? address,
    bool? isDefault,
    String? id,
    String? note,
    String? phoneNumber,
  });

  Future<Place> setDefaultPlace(String id);

  Future<Place?> getDefaultPlace();
}
