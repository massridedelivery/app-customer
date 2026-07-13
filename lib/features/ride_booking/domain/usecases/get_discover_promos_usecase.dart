import 'package:customer_app/features/ride_booking/domain/models/ride_promo.dart';
import 'package:customer_app/features/ride_booking/domain/repositories/ride_booking_repository.dart';
import 'package:customer_app/features/ride_booking/data/repositories/ride_booking_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getDiscoverPromosUseCaseProvider = Provider.autoDispose<GetDiscoverPromosUseCase>((ref) {
  final repository = ref.watch(rideBookingRepositoryProvider);
  return GetDiscoverPromosUseCase(repository);
});

class GetDiscoverPromosUseCase {
  final RideBookingRepository _repository;

  GetDiscoverPromosUseCase(this._repository);

  Future<List<RidePromo>> call() {
    return _repository.getDiscoverPromos();
  }
}
