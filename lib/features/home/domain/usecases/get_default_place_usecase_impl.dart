import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/repositories/place_repository.dart';
import 'package:customer_app/features/home/data/repositories/place_repository_impl.dart';
import 'package:customer_app/features/home/domain/usecases/get_default_place_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_default_place_usecase_impl.g.dart';

@riverpod
GetDefaultPlaceUseCaseImpl getDefaultPlaceUseCase(Ref ref) {
  final repository = ref.watch(placeRepositoryProvider);
  return GetDefaultPlaceUseCaseImpl(repository);
}

class GetDefaultPlaceUseCaseImpl implements GetDefaultPlaceUseCase {
  final PlaceRepository _repository;

  GetDefaultPlaceUseCaseImpl(this._repository);

  @override
  Future<Place?> call() {
    return _repository.getDefaultPlace();
  }
}
