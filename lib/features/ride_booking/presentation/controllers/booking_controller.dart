import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/domain/usecases/estimate_fare_usecase_impl.dart';
import 'package:customer_app/features/ride_booking/domain/usecases/validate_promo_usecase_impl.dart';
import 'package:customer_app/features/ride_booking/domain/usecases/dispatch_ride_usecase_impl.dart';

part 'booking_controller.g.dart';

@riverpod
class BookingController extends _$BookingController {
  @override
  FutureOr<BookingState> build() {
    return const BookingState();
  }

  Future<void> estimateFare(
    LatLng pickup,
    LatLng dropoff, {
    String? promoCode,
    String? vehicleTypeId,
  }) async {
    // Snapshot current state BEFORE setting loading — once state is AsyncLoading,
    // state.value returns null and we would lose the existing booking data.
    final previousState = state.value ?? const BookingState();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(estimateFareUseCaseProvider);
      final response = await useCase(
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropoffLat: dropoff.latitude,
        dropoffLng: dropoff.longitude,
        promoCode: promoCode,
        vehicleTypeId: vehicleTypeId,
      );

      return previousState.copyWith(
        isLoading: false,
        estimations: response.estimations,
        distanceKm: response.distanceKm,
        durationMin: response.durationMin.toDouble(),
        encodedPolyline: response.waypoint,
        surgeMultiplier: response.surgeMultiplier,
        appliedPromoCode: promoCode,
        // Clear the stashed coupon discount when the promo is removed.
        promoDiscount: promoCode == null ? 0.0 : previousState.promoDiscount,
        error: null,
      );
    });
  }

  Future<bool> validatePromo(String code) async {
    final useCase = ref.read(validatePromoUseCaseProvider);
    final currentState = state.value ?? const BookingState();
    double subtotal = 0.0;
    if (currentState.estimations.isNotEmpty) {
      final selectedVehicleId = currentState.vehicleTypeId;
      if (selectedVehicleId != null) {
        final estimation = currentState.estimations.firstWhere(
          (e) => e.vehicleTypeId == selectedVehicleId,
          orElse: () => currentState.estimations.first,
        );
        subtotal = estimation.totalFare + estimation.discount;
      } else {
        final firstEst = currentState.estimations.first;
        subtotal = firstEst.totalFare + firstEst.discount;
      }
    }
    // Throws on an invalid code (handled by the coupon screen); on success it
    // returns the discount, which we stash so the UI can display it. The
    // subsequent re-estimate preserves this via copyWith.
    final discount = await useCase(code, subtotal);
    state = AsyncValue.data(currentState.copyWith(promoDiscount: discount));
    return true;
  }

  Future<bool> dispatchRide({
    required LatLng pickup,
    required LatLng dropoff,
    required String pickupAddress,
    required String dropoffAddress,
  }) async {
    final currentState = state.value ?? const BookingState();
    state = const AsyncValue.loading();

    String? jobId;
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(dispatchRideUseCaseProvider);
      jobId = await useCase(
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        pickupAddress: pickupAddress,
        dropoffLat: dropoff.latitude,
        dropoffLng: dropoff.longitude,
        dropoffAddress: dropoffAddress,
        paymentMethod: currentState.paymentMethod,
        vehicleTypeId: currentState.vehicleTypeId,
        promoCode: currentState.appliedPromoCode,
      );
      return currentState.copyWith(
        isLoading: false,
        activeJobId: jobId,
        error: null,
      );
    });

    return jobId != null;
  }

  void setPaymentMethod(String method) {
    final currentState = state.value ?? const BookingState();
    state = AsyncValue.data(currentState.copyWith(paymentMethod: method));
  }

  void setVehicleType(String? vehicleTypeId) {
    final currentState = state.value ?? const BookingState();
    state = AsyncValue.data(
      currentState.copyWith(vehicleTypeId: vehicleTypeId),
    );
  }

  String getVehicleIcon(String typeName) {
    final lowerName = typeName.toLowerCase();
    if (lowerName.contains('bike') || lowerName.contains('motorcycle')) {
      return 'assets/images/icons/ic_bike_custom.png';
    }
    if (lowerName.contains('eco') || lowerName.contains('saver')) {
      return 'assets/images/icons/ic_ride_eco_custom.png';
    }
    if (lowerName.contains('tuk')) {
      return 'assets/images/icons/ic_ride_eco_custom.png'; // Fallback for Tuk-Tuk
    }
    if (lowerName.contains('van')) {
      return 'assets/images/icons/ic_taxi_custom.png'; // Fallback for Van
    }
    return 'assets/images/icons/ic_taxi_custom.png';
  }

  void restoreFromActiveJob({
    required double? distanceKm,
    required double? durationMin,
    required String? polyline,
  }) {
    final currentState = state.value ?? const BookingState();
    state = AsyncValue.data(
      currentState.copyWith(
        distanceKm: distanceKm,
        durationMin: durationMin,
        encodedPolyline: (polyline != null && polyline.isNotEmpty)
            ? polyline
            : null,
      ),
    );
  }
}
