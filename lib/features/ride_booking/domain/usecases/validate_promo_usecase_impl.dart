import 'package:customer_app/features/ride_booking/domain/repositories/ride_booking_repository.dart';
import 'package:customer_app/features/ride_booking/data/repositories/ride_booking_repository_impl.dart';
import 'package:customer_app/features/ride_booking/domain/usecases/validate_promo_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'validate_promo_usecase_impl.g.dart';

@riverpod
ValidatePromoUseCaseImpl validatePromoUseCase(Ref ref) {
  final repository = ref.watch(rideBookingRepositoryProvider);
  return ValidatePromoUseCaseImpl(repository);
}

class ValidatePromoUseCaseImpl implements ValidatePromoUseCase {
  final RideBookingRepository _repository;

  ValidatePromoUseCaseImpl(this._repository);

  @override
  Future<double> call(String code, double subtotal) {
    return _repository.validatePromo(code, subtotal);
  }
}
