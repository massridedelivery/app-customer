import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/utils/either.dart';
import 'package:customer_app/features/live_ride/data/datasources/live_ride_data_source.dart';
import 'package:customer_app/features/live_ride/domain/repositories/live_ride_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'live_ride_repository_impl.g.dart';

@riverpod
LiveRideRepositoryImpl liveRideRepository(Ref ref) {
  final dataSource = ref.watch(liveRideDataSourceProvider);
  return LiveRideRepositoryImpl(dataSource);
}

class LiveRideRepositoryImpl implements LiveRideRepository {
  final LiveRideDataSource _dataSource;

  LiveRideRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, void>> cancelRide(String jobId) async {
    try {
      await _dataSource.cancelRide(jobId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(
        ServerFailure(e.response?.data['message'] ?? 'Failed to cancel ride'),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
