import 'package:customer_app/features/ride_booking/domain/models/fare_estimation_response.dart';
import 'package:customer_app/features/ride_booking/domain/repositories/ride_booking_repository.dart';
import 'package:customer_app/features/ride_booking/data/repositories/ride_booking_repository_impl.dart';
import 'package:customer_app/features/ride_booking/domain/usecases/estimate_fare_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'estimate_fare_usecase_impl.g.dart';

@riverpod
EstimateFareUseCaseImpl estimateFareUseCase(Ref ref) {
  final repository = ref.watch(rideBookingRepositoryProvider);
  return EstimateFareUseCaseImpl(repository);
}

class EstimateFareUseCaseImpl implements EstimateFareUseCase {
  final RideBookingRepository _repository;

  EstimateFareUseCaseImpl(this._repository);

  @override
  Future<FareEstimationResponse> call({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? promoCode,
    String? vehicleTypeId,
  }) {
    return _repository.estimateFare(
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      promoCode: promoCode,
      vehicleTypeId: vehicleTypeId,
    );
  }
}
