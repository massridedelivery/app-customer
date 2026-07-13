import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/repositories/place_repository.dart';
import 'package:customer_app/features/home/data/repositories/place_repository_impl.dart';
import 'package:customer_app/features/home/domain/usecases/get_recent_places_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_recent_places_usecase_impl.g.dart';

@riverpod
GetRecentPlacesUseCaseImpl getRecentPlacesUseCase(Ref ref) {
  final repository = ref.watch(placeRepositoryProvider);
  return GetRecentPlacesUseCaseImpl(repository);
}

class GetRecentPlacesUseCaseImpl implements GetRecentPlacesUseCase {
  final PlaceRepository _repository;

  GetRecentPlacesUseCaseImpl(this._repository);

  @override
  Future<List<Place>> call() {
    return _repository.getRecentPlaces();
  }
}
