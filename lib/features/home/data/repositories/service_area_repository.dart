import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/home/domain/models/service_area_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceAreaRepositoryProvider = Provider<ServiceAreaRepository>((ref) {
  return ServiceAreaRepository(ref.watch(apiServiceProvider));
});

/// Checks whether a service (ride/messenger) has an open service zone at the
/// customer's current coordinates (SCRUM zone-availability API).
///
/// **Fail-open**: any error — including the endpoint not existing yet — returns
/// [ServiceAreaResult.openFallback] so the booking flow keeps working exactly as
/// today until the backend ships. Only an explicit `available:false` from the
/// backend gates the customer to the "coming soon in your area" screen.
class ServiceAreaRepository {
  final ApiService _apiService;

  ServiceAreaRepository(this._apiService);

  Future<ServiceAreaResult> check({
    required double lat,
    required double lng,
    String service = 'ride',
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/service-area/check',
        queryParameters: {'lat': lat, 'lng': lng, 'service': service},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ServiceAreaResult.fromJson(data);
      }
      return ServiceAreaResult.openFallback;
    } catch (e) {
      debugPrint('ServiceAreaRepository.check failed (fail-open): $e');
      return ServiceAreaResult.openFallback;
    }
  }
}
