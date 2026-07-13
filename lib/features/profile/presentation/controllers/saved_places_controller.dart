import 'package:customer_app/features/home/data/datasources/place_data_source.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/usecases/get_saved_places_usecase_impl.dart';
import 'package:customer_app/features/profile/presentation/states/saved_places_state.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_places_controller.g.dart';

@riverpod
class SavedPlacesController extends _$SavedPlacesController {
  @override
  FutureOr<SavedPlacesState> build() async {
    final places = await _fetchPlaces();
    return SavedPlacesState(
      places: AsyncData(places),
    );
  }

  Future<List<Place>> _fetchPlaces() async {
    return ref.read(getSavedPlacesUseCaseProvider).call();
  }

  Future<void> refreshPlaces() async {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncData(currentState.copyWith(places: const AsyncLoading()));
    } else {
      state = const AsyncLoading();
    }
    
    final result = await AsyncValue.guard(() => _fetchPlaces());
    state = AsyncData(
      SavedPlacesState(places: result),
    );
  }

  Future<bool> deletePlace(String id) async {
    final currentState = state.value;
    if (currentState == null) return false;

    state = AsyncData(currentState.copyWith(isDeleting: true, error: null));

    final deleteResult = await AsyncValue.guard(() async {
      await ref.read(placeDataSourceProvider).deleteSavedPlace(id);
    });

    if (deleteResult.hasError) {
      state = AsyncData(
        currentState.copyWith(
          isDeleting: false,
          error: deleteResult.error?.toString() ?? 'Failed to delete saved place',
        ),
      );
      return false;
    }

    final newPlacesResult = await AsyncValue.guard(() => _fetchPlaces());
    
    // Refresh home controller state to pick up the changes
    await ref.read(homeControllerProvider.notifier).refreshSavedPlaces();

    state = AsyncData(
      SavedPlacesState(
        places: newPlacesResult,
        isDeleting: false,
      ),
    );
    return true;
  }
}
