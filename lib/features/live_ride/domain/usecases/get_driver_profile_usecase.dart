import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';
import 'package:customer_app/features/live_ride/data/repositories/driver_profile_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_driver_profile_usecase.g.dart';

@riverpod
class GetDriverProfileUsecase extends _$GetDriverProfileUsecase {
  @override
  Future<CustomerJobsActiveModel> build() async {
    final repository = ref.watch(driverProfileRepositoryProvider);
    return repository.getDriverProfile();
  }
}
