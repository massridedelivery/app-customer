import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'live_ride_data_source.g.dart';

abstract class LiveRideDataSource {
  Future<Map<String, dynamic>> cancelRide(String jobId);
}

@riverpod
LiveRideDataSourceImpl liveRideDataSource(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return LiveRideDataSourceImpl(apiService);
}

class LiveRideDataSourceImpl implements LiveRideDataSource {
  final ApiService _apiService;

  LiveRideDataSourceImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> cancelRide(String jobId) async {
    final response = await _apiService.dio.post(
      '/api/customer/jobs/$jobId/cancel',
    );
    return response.data as Map<String, dynamic>;
  }
}
