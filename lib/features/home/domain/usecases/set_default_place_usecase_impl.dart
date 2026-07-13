import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/repositories/place_repository.dart';
import 'package:customer_app/features/home/data/repositories/place_repository_impl.dart';
import 'package:customer_app/features/home/domain/usecases/set_default_place_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_default_place_usecase_impl.g.dart';

@riverpod
SetDefaultPlaceUseCaseImpl setDefaultPlaceUseCase(Ref ref) {
  final repository = ref.watch(placeRepositoryProvider);
  return SetDefaultPlaceUseCaseImpl(repository);
}

class SetDefaultPlaceUseCaseImpl implements SetDefaultPlaceUseCase {
  final PlaceRepository _repository;

  SetDefaultPlaceUseCaseImpl(this._repository);

  @override
  Future<Place> call(String id) {
    return _repository.setDefaultPlace(id);
  }
}
