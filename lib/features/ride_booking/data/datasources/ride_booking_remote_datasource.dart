import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ride_booking_remote_datasource.g.dart';

abstract class RideBookingRemoteDataSource {
  Future<Map<String, dynamic>> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? promoCode,
    String? vehicleTypeId,
  });

  Future<Map<String, dynamic>> validatePromo(String code, double subtotal);

  Future<List<dynamic>> getDiscoverPromos();

  Future<Map<String, dynamic>> createJob({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String paymentMethod,
    String? vehicleTypeId,
    String? promoCode,
  });
}

@riverpod
RideBookingRemoteDataSourceImpl rideBookingRemoteDataSource(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RideBookingRemoteDataSourceImpl(apiService);
}

class RideBookingRemoteDataSourceImpl implements RideBookingRemoteDataSource {
  final ApiService _apiService;

  RideBookingRemoteDataSourceImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? promoCode,
    String? vehicleTypeId,
  }) async {
    final response = await _apiService.dio.post(
      '/api/customer/jobs/estimate',
      data: {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'dropoff_lat': dropoffLat,
        'dropoff_lng': dropoffLng,
        'promo_code': ?promoCode,
        'vehicle_type_id': ?vehicleTypeId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> validatePromo(String code, double subtotal) async {
    final response = await _apiService.dio.post(
      '/api/customer/promos/validate',
      data: {
        'promo_codes': [code],
        'subtotal': subtotal,
        'applies_to': 'RIDE',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<dynamic>> getDiscoverPromos() async {
    final response = await _apiService.dio.get(
      '/api/customer/promos/context',
      queryParameters: {
        'applies_to': 'RIDE',
      },
    );
    return (response.data as List<dynamic>?) ?? [];
  }

  @override
  Future<Map<String, dynamic>> createJob({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String paymentMethod,
    String? vehicleTypeId,
    String? promoCode,
  }) async {
    final response = await _apiService.dio.post(
      '/api/customer/jobs',
      data: {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'pickup_address': pickupAddress,
        'dropoff_lat': dropoffLat,
        'dropoff_lng': dropoffLng,
        'dropoff_address': dropoffAddress,
        'payment_method': paymentMethod,
        'vehicle_type_id': vehicleTypeId,
        'promo_code': ?promoCode,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
