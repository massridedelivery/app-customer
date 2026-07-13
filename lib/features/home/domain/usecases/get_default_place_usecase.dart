import 'package:customer_app/features/home/domain/models/place.dart';

abstract class GetDefaultPlaceUseCase {
  Future<Place?> call();
}
