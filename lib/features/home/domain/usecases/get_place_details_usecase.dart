import 'package:customer_app/features/home/domain/models/place.dart';

abstract class GetPlaceDetailsUseCase {
  Future<Place> call(String placeId);
}
