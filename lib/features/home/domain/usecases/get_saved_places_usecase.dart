import 'package:customer_app/features/home/domain/models/place.dart';

abstract class GetSavedPlacesUseCase {
  Future<List<Place>> call();
}
