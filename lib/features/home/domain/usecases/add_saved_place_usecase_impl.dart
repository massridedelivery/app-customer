import 'package:customer_app/features/home/domain/repositories/place_repository.dart';
import 'package:customer_app/features/home/data/repositories/place_repository_impl.dart';
import 'package:customer_app/features/home/domain/usecases/add_saved_place_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_saved_place_usecase_impl.g.dart';

@riverpod
AddSavedPlaceUseCaseImpl addSavedPlaceUseCase(Ref ref) {
  final repository = ref.watch(placeRepositoryProvider);
  return AddSavedPlaceUseCaseImpl(repository);
}

class AddSavedPlaceUseCaseImpl implements AddSavedPlaceUseCase {
  final PlaceRepository _repository;

  AddSavedPlaceUseCaseImpl(this._repository);

  @override
  Future<void> call({
    required String name,
    required double lat,
    required double lng,
    String? address,
    bool? isDefault,
    String? id,
    String? note,
    String? phoneNumber,
  }) {
    return _repository.addSavedPlace(
      name: name,
      lat: lat,
      lng: lng,
      address: address,
      isDefault: isDefault,
      id: id,
      note: note,
      phoneNumber: phoneNumber,
    );
  }
}
