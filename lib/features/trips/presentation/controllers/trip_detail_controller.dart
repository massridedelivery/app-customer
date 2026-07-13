import 'package:customer_app/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:customer_app/features/trips/presentation/states/trip_detail_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trip_detail_controller.g.dart';

@riverpod
class TripDetailController extends _$TripDetailController {
  @override
  TripDetailState build() {
    return const TripDetailState();
  }

  Future<void> fetchFoodOrderDetail(String id) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      foodDetails: null,
      rideDetails: null,
    );
    try {
      final repository = ref.read(tripsRepositoryProvider);
      final details = await repository.getFoodOrderDetail(id);
      state = state.copyWith(isLoading: false, foodDetails: details);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchRideOrderDetail(String id) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      foodDetails: null,
      rideDetails: null,
    );
    try {
      final repository = ref.read(tripsRepositoryProvider);
      final details = await repository.getRideOrderDetail(id);
      state = state.copyWith(isLoading: false, rideDetails: details);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
