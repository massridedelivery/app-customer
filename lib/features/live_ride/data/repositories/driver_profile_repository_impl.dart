import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';
import 'package:customer_app/features/live_ride/domain/repositories/i_driver_profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'driver_profile_repository_impl.g.dart';

@riverpod
IDriverProfileRepository driverProfileRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DriverProfileRepositoryImpl(apiService);
}

class DriverProfileRepositoryImpl implements IDriverProfileRepository {
  final ApiService _apiService;

  DriverProfileRepositoryImpl(this._apiService);

  @override
  Future<CustomerJobsActiveModel> getDriverProfile() async {
    try {
      final response = await _apiService.dio.get('/api/customer/jobs/active');
      return CustomerJobsActiveModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      // 404 = the customer has no active job yet (e.g. still searching for a
      // driver). Surface it distinctly so callers can treat it as "keep
      // waiting" rather than a hard error.
      if (e.response?.statusCode == 404) {
        throw Exception('NO_ACTIVE_JOB');
      }
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      throw Exception(message ?? 'Failed to fetch driver profile');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<String?> getJobStatus(String jobId) async {
    try {
      final response = await _apiService.dio.get('/api/customer/jobs/$jobId');
      final data = response.data;
      final status = data is Map ? data['status'] : null;
      return status is String && status.isNotEmpty
          ? status.toUpperCase()
          : null;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 403) return null;
      rethrow;
    }
  }
}
