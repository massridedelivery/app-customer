import 'package:customer_app/features/ride_booking/data/datasources/ride_booking_remote_datasource.dart';
import 'package:customer_app/features/ride_booking/domain/models/fare_estimation_response.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_promo.dart';
import 'package:customer_app/features/ride_booking/domain/repositories/ride_booking_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ride_booking_repository_impl.g.dart';

@riverpod
RideBookingRepository rideBookingRepository(Ref ref) {
  final dataSource = ref.watch(rideBookingRemoteDataSourceProvider);
  return RideBookingRepositoryImpl(dataSource);
}

class RideBookingRepositoryImpl implements RideBookingRepository {
  final RideBookingRemoteDataSource _dataSource;

  RideBookingRepositoryImpl(this._dataSource);

  @override
  Future<FareEstimationResponse> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? promoCode,
    String? vehicleTypeId,
  }) async {
    try {
      final response = await _dataSource.estimateFare(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        promoCode: promoCode,
        vehicleTypeId: vehicleTypeId,
      );

      return FareEstimationResponse.fromJson(response);
    } catch (e) {
      // โยน Custom Exception ออกไปให้ Riverpod Controller เป็นคนจัดการ (เช่น ผ่าน AsyncValue.guard)
      throw Exception('Failed to estimate fare: $e');
    }
  }

  @override
  Future<double> validatePromo(String code, double subtotal) async {
    try {
      final response = await _dataSource.validatePromo(code, subtotal);
      final applied = response['applied'] as List<dynamic>?;
      final upperCode = code.toUpperCase();
      final isApplied = applied != null &&
          applied.any((item) =>
              item is Map &&
              item['code']?.toString().toUpperCase() == upperCode);
      if (!isApplied) {
        throw Exception('Promo code not applied');
      }
      // Prefer the server-computed total; fall back to summing applied lines.
      final total = (response['total_discount'] as num?)?.toDouble();
      if (total != null) return total;
      double sum = 0.0;
      for (final item in applied) {
        if (item is Map) {
          sum += (item['discount_amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return sum;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'] ?? 'Invalid Promo Code';
        throw Exception(message);
      }
      throw Exception('Failed to validate promo code: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<RidePromo>> getDiscoverPromos() async {
    try {
      final list = await _dataSource.getDiscoverPromos();
      return list.map((json) {
        if (json is Map) {
          return RidePromo.fromJson(Map<String, dynamic>.from(json));
        }
        throw Exception('Invalid promo format');
      }).toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'] ?? 'Failed to fetch promotions';
        throw Exception(message);
      }
      throw Exception('Failed to fetch promotions: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<String> createJob({
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
    try {
      final response = await _dataSource.createJob(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        pickupAddress: pickupAddress,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        dropoffAddress: dropoffAddress,
        paymentMethod: paymentMethod,
        vehicleTypeId: vehicleTypeId,
        promoCode: promoCode,
      );
      return response['id'] as String;
    } catch (e) {
      // โยน Custom Exception ออกไปให้ Riverpod Controller เป็นคนจัดการ (เช่น ผ่าน AsyncValue.guard)
      throw Exception('Failed to create job: $e');
    }
  }
}
