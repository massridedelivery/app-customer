import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/utils/either.dart';

abstract class LiveRideRepository {
  Future<Either<Failure, void>> cancelRide(String jobId);
}
