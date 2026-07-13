import 'package:customer_app/features/home/domain/models/place_prediction.dart';
import 'package:customer_app/features/home/domain/repositories/place_repository.dart';
import 'package:customer_app/features/home/data/repositories/place_repository_impl.dart';
import 'package:customer_app/features/home/domain/usecases/search_places_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_places_usecase_impl.g.dart';

@riverpod
SearchPlacesUseCaseImpl searchPlacesUseCase(Ref ref) {
  final repository = ref.watch(placeRepositoryProvider);
  return SearchPlacesUseCaseImpl(repository);
}

class SearchPlacesUseCaseImpl implements SearchPlacesUseCase {
  final PlaceRepository _repository;

  SearchPlacesUseCaseImpl(this._repository);

  @override
  Future<List<PlacePrediction>> call(
    String query, {
    double? lat,
    double? lng,
  }) {
    return _repository.autocomplete(query, lat: lat, lng: lng);
  }
}
