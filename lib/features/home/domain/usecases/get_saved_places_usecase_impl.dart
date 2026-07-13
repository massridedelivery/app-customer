import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/repositories/place_repository.dart';
import 'package:customer_app/features/home/data/repositories/place_repository_impl.dart';
import 'package:customer_app/features/home/domain/usecases/get_saved_places_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_saved_places_usecase_impl.g.dart';

@riverpod
GetSavedPlacesUseCaseImpl getSavedPlacesUseCase(Ref ref) {
  final repository = ref.watch(placeRepositoryProvider);
  return GetSavedPlacesUseCaseImpl(repository);
}

class GetSavedPlacesUseCaseImpl implements GetSavedPlacesUseCase {
  final PlaceRepository _repository;

  GetSavedPlacesUseCaseImpl(this._repository);

  @override
  Future<List<Place>> call() {
    return _repository.getSavedPlaces();
  }
}
