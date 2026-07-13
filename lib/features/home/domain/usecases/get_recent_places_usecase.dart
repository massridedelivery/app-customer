import 'package:customer_app/features/home/domain/models/place.dart';

abstract class GetRecentPlacesUseCase {
  Future<List<Place>> call();
}
