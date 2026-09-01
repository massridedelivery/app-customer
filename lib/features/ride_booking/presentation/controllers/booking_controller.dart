import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
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

  /// The ride page ("การรับส่งผู้โดยสาร") is passenger transport only, but the
  /// backend fare estimate can include messenger (delivery) vehicle types like
  /// "Messenger Bike" / "รถส่งของ". Drop those so only passenger vehicles show.
  List<VehicleEstimation> _passengerOnly(List<VehicleEstimation> all) {
    return all.where((e) {
      final key = '${e.vehicleTypeName} ${e.displayName}'.toLowerCase();
      return !key.contains('messenger') && !key.contains('ส่งของ');
    }).toList();
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
        estimations: _passengerOnly(response.estimations),
        nearbyDrivers: response.nearbyDrivers,
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

  /// Re-fetch the estimate WITHOUT flipping to AsyncLoading, updating the
  /// per-vehicle nearby-driver counts / prices in place. Used by the vehicle
  /// screen's ~30s refresh so the sheet never flashes a spinner. No-op unless an
  /// estimate is already loaded and no ride is being dispatched; errors are
  /// swallowed so a transient failure keeps the last good estimate on screen.
  Future<void> refreshEstimate(
    LatLng pickup,
    LatLng dropoff, {
    String? promoCode,
  }) async {
    final current = state.value;
    if (current == null ||
        current.estimations.isEmpty ||
        current.activeJobId != null) {
      return;
    }
    try {
      final response = await ref.read(estimateFareUseCaseProvider)(
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropoffLat: dropoff.latitude,
        dropoffLng: dropoff.longitude,
        promoCode: promoCode,
      );
      final latest = state.value;
      // A dispatch / fresh estimate may have landed during the await.
      if (latest == null || latest.activeJobId != null) return;
      state = AsyncValue.data(
        latest.copyWith(
          estimations: _passengerOnly(response.estimations),
          nearbyDrivers: response.nearbyDrivers,
          distanceKm: response.distanceKm,
          durationMin: response.durationMin.toDouble(),
          encodedPolyline: response.waypoint,
          surgeMultiplier: response.surgeMultiplier,
        ),
      );
    } catch (_) {
      // Silent background refresh — keep the last estimate on any failure.
    }
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

  // Mass-liveried 3/4 vehicle icons (AI-rendered originals, brand-red with the
  // Mass "M" door decal) under assets/images/icons/3d/.
  String getVehicleIcon(String typeName) {
    final n = typeName.toLowerCase();
    if (n.contains('bike') || n.contains('motorcycle')) {
      return 'assets/images/icons/3d/ic_car_scooter.png';
    }
    if (n.contains('luxury')) {
      return 'assets/images/icons/3d/ic_car_luxury.png';
    }
    if (n.contains('premium')) {
      return 'assets/images/icons/3d/ic_car_premium.png';
    }
    if (n.contains('xl') ||
        n.contains('van') ||
        n.contains('suv') ||
        n.contains('6')) {
      return 'assets/images/icons/3d/ic_car_xl.png';
    }
    if (n.contains('comfort')) {
      return 'assets/images/icons/3d/ic_car_comfort.png';
    }
    // economy / saver / eco / tuk-tuk and anything else → the clean sedan.
    return 'assets/images/icons/3d/ic_car_economy.png';
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
