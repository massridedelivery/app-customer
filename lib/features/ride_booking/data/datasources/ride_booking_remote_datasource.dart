import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/core/services/idempotency.dart';
import 'package:dio/dio.dart';
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
    bool? usePoints,
    int? pointsToUse,
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
    bool? usePoints,
    int? pointsToUse,
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
    bool? usePoints,
    int? pointsToUse,
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
        // Points: use_points alone = as many as allowed; points_to_use = an
        // exact amount (BE §3.1).
        'use_points': ?usePoints,
        'points_to_use': ?pointsToUse,
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
    bool? usePoints,
    int? pointsToUse,
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
        // The same points choice as the last estimate.
        'use_points': ?usePoints,
        'points_to_use': ?pointsToUse,
      },
      // Retry-safe create (SCRUM-50): a replay after a 503/timeout returns the
      // original job instead of double-booking.
      options: Options(headers: {kIdempotencyHeader: generateIdempotencyKey()}),
    );
    return response.data as Map<String, dynamic>;
  }
}
