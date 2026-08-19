import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/utils/either.dart';

abstract class CancelRideUseCase {
  Future<Either<Failure, double>> call(String jobId);
}
