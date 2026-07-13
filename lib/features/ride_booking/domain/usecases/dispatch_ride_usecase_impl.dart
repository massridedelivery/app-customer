import 'package:customer_app/features/ride_booking/domain/repositories/ride_booking_repository.dart';
import 'package:customer_app/features/ride_booking/data/repositories/ride_booking_repository_impl.dart';
import 'package:customer_app/features/ride_booking/domain/usecases/dispatch_ride_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dispatch_ride_usecase_impl.g.dart';

@riverpod
DispatchRideUseCaseImpl dispatchRideUseCase(Ref ref) {
  final repository = ref.watch(rideBookingRepositoryProvider);
  return DispatchRideUseCaseImpl(repository);
}

class DispatchRideUseCaseImpl implements DispatchRideUseCase {
  final RideBookingRepository _repository;

  DispatchRideUseCaseImpl(this._repository);

  @override
  Future<String> call({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String paymentMethod,
    String? vehicleTypeId,
    String? promoCode,
  }) {
    return _repository.createJob(
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupAddress: pickupAddress,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      dropoffAddress: dropoffAddress,
      paymentMethod: paymentMethod,
      vehicleTypeId: vehicleTypeId,
      promoCode: promoCode,
    );
  }
}
