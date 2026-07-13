import 'package:customer_app/features/home/domain/models/place_prediction.dart';

abstract class SearchPlacesUseCase {
  Future<List<PlacePrediction>> call(
    String query, {
    double? lat,
    double? lng,
  });
}
