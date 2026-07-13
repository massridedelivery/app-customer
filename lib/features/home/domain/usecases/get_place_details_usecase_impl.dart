import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/repositories/place_repository.dart';
import 'package:customer_app/features/home/data/repositories/place_repository_impl.dart';
import 'package:customer_app/features/home/domain/usecases/get_place_details_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_place_details_usecase_impl.g.dart';

@riverpod
GetPlaceDetailsUseCaseImpl getPlaceDetailsUseCase(Ref ref) {
  final repository = ref.watch(placeRepositoryProvider);
  return GetPlaceDetailsUseCaseImpl(repository);
}

class GetPlaceDetailsUseCaseImpl implements GetPlaceDetailsUseCase {
  final PlaceRepository _repository;

  GetPlaceDetailsUseCaseImpl(this._repository);

  @override
  Future<Place> call(String placeId) {
    return _repository.getPlaceDetails(placeId);
  }
}
