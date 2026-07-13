import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/utils/either.dart';
import 'package:customer_app/features/live_ride/domain/repositories/live_ride_repository.dart';
import 'package:customer_app/features/live_ride/data/repositories/live_ride_repository_impl.dart';
import 'package:customer_app/features/live_ride/domain/usecases/cancel_ride_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cancel_ride_usecase_impl.g.dart';

@riverpod
CancelRideUseCaseImpl cancelRideUseCase(Ref ref) {
  final repository = ref.watch(liveRideRepositoryProvider);
  return CancelRideUseCaseImpl(repository);
}

class CancelRideUseCaseImpl implements CancelRideUseCase {
  final LiveRideRepository _repository;

  CancelRideUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, void>> call(String jobId) {
    return _repository.cancelRide(jobId);
  }
}
