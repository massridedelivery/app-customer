import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/utils/either.dart';

abstract class LiveRideRepository {
  /// Returns the cancellation fee actually charged (0 when none).
  Future<Either<Failure, double>> cancelRide(String jobId);
}
