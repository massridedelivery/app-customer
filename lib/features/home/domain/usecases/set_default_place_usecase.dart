import 'package:customer_app/features/home/domain/models/place.dart';

abstract class SetDefaultPlaceUseCase {
  Future<Place> call(String id);
}
