import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/localization/locale_controller.dart';
import 'package:customer_app/core/utils/promo_rejection.dart';
import 'package:customer_app/features/ride_booking/data/datasources/ride_booking_remote_datasource.dart';
import 'package:customer_app/features/ride_booking/domain/models/fare_estimation_response.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_promo.dart';
import 'package:customer_app/features/ride_booking/domain/repositories/ride_booking_repository.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ride_booking_repository_impl.g.dart';

@riverpod
RideBookingRepository rideBookingRepository(Ref ref) {
  final dataSource = ref.watch(rideBookingRemoteDataSourceProvider);
  return RideBookingRepositoryImpl(
    dataSource,
    // Fallback error text follows the app language at the time of the error.
    l10n: () => lookupAppLocalizations(
      Locale(ref.read(localeControllerProvider).languageCode),
    ),
  );
}

class RideBookingRepositoryImpl implements RideBookingRepository {
  final RideBookingRemoteDataSource _dataSource;
  final AppLocalizations Function() _l10n;

  RideBookingRepositoryImpl(
    this._dataSource, {
    AppLocalizations Function()? l10n,
  }) : _l10n = l10n ?? (() => lookupAppLocalizations(const Locale('th')));

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
    } on DioException catch (e) {
      // Surface the server's actual validation detail (which field/rule failed)
      // to the logs — this is what explains a 422 instead of a generic string.
      debugPrint(
        'estimateFare failed: ${e.response?.statusCode} ${e.response?.data}',
      );
      throw Exception(
        apiErrorMessage(e, fallback: _l10n().rideFareEstimateFailed),
      );
    } catch (e) {
      throw Exception(
        apiErrorMessage(e, fallback: _l10n().rideFareEstimateFailed),
      );
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
        throw Exception(promoRejectionMessage(response, upperCode));
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
        final message = data['message'] ?? data['error'];
        throw Exception(
          promoReasonToThai(message?.toString()) ?? kPromoRejectedFallback,
        );
      }
      throw Exception(kPromoRejectedFallback);
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
    } on DioException catch (e) {
      debugPrint(
        'createJob failed: ${e.response?.statusCode} ${e.response?.data}',
      );
      throw Exception(
        apiErrorMessage(e, fallback: _l10n().rideRequestFailed),
      );
    } catch (e) {
      throw Exception(
        apiErrorMessage(e, fallback: _l10n().rideRequestFailed),
      );
    }
  }
}
