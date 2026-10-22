import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/features/profile/data/welcome_promo_store.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_quote.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/domain/usecases/estimate_fare_usecase_impl.dart';
import 'package:customer_app/features/ride_booking/domain/usecases/validate_promo_usecase_impl.dart';
import 'package:customer_app/features/ride_booking/domain/usecases/dispatch_ride_usecase_impl.dart';

part 'booking_controller.g.dart';

enum DispatchOutcome { booked, priceChanged, failed }

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
    final next = await AsyncValue.guard(() async {
      final useCase = ref.read(estimateFareUseCaseProvider);
      final response = await useCase(
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropoffLat: dropoff.latitude,
        dropoffLng: dropoff.longitude,
        promoCode: promoCode,
        vehicleTypeId: vehicleTypeId,
        usePoints: previousState.usePoints ? true : null,
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
        // A fresh estimate invalidates any reason fetched for the old one.
        promoRejectReason: null,
        // Clear the stashed coupon discount when the promo is removed.
        promoDiscount: promoCode == null ? 0.0 : previousState.promoDiscount,
        error: null,
        estimatedAt: DateTime.now(),
      );
    });
    state = next;

    // Points that can't be used fail the estimate (the error is shown from
    // the AsyncError): drop points when they're switched off / need a login,
    // and price again.
    final error = next.error;
    if (error is ApiError && (error.code?.startsWith('POINTS_') ?? false)) {
      final off =
          error.code == 'POINTS_DISABLED' ||
          error.code == 'POINTS_LOGIN_REQUIRED';
      state = AsyncValue.data(
        previousState.copyWith(
          usePoints: off ? false : previousState.usePoints,
          pointsDisabled:
              error.code == 'POINTS_DISABLED' || previousState.pointsDisabled,
        ),
      );
      await estimateFare(
        pickup,
        dropoff,
        promoCode: promoCode,
        vehicleTypeId: vehicleTypeId,
      );
      return;
    }
  }

  /// The selected vehicle's estimation (the first one before a pick).
  VehicleEstimation? _selected(BookingState s) {
    if (s.estimations.isEmpty) return null;
    return s.estimations.firstWhere(
      (e) => e.vehicleTypeId == s.vehicleTypeId,
      orElse: () => s.estimations.first,
    );
  }

  /// The "ใช้คะแนน" switch: on = as many points as allowed, off = none.
  Future<void> setUsePoints(
    bool on,
    LatLng pickup,
    LatLng dropoff,
  ) async {
    final current = state.value ?? const BookingState();
    state = AsyncValue.data(current.copyWith(usePoints: on));
    await estimateFare(pickup, dropoff, promoCode: current.appliedPromoCode);
  }

  /// Points start off every time the booking screen opens — the choice is
  /// never carried over from an earlier booking.
  void resetPointsChoice() {
    final current = state.value;
    if (current == null || !current.usePoints) return;
    state = AsyncValue.data(current.copyWith(usePoints: false));
  }

  /// The screen showed the dropped-code notice.
  void clearNotices() {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(promoDroppedOnBooking: false));
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
        usePoints: current.usePoints ? true : null,
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
          estimatedAt: DateTime.now(),
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

  /// Why [code] took nothing off the current estimate, from /promos/validate
  /// (already localized), or null when validate accepts it / can't say.
  /// Also stores it on the state so the sheet's coupon note can show it.
  Future<String?> promoRejectionReason(String code) async {
    final current = state.value ?? const BookingState();
    String? reason;
    try {
      await ref.read(validatePromoUseCaseProvider)(code, _subtotal(current));
    } catch (e) {
      reason = e.toString().replaceFirst('Exception: ', '').trim();
      if (reason.isEmpty) reason = null;
    }
    final latest = state.value;
    if (latest != null && latest.appliedPromoCode == code) {
      state = AsyncValue.data(latest.copyWith(promoRejectReason: reason));
    }
    return reason;
  }

  double _subtotal(BookingState s) {
    if (s.estimations.isEmpty) return 0;
    final e = s.estimations.firstWhere(
      (e) => e.vehicleTypeId == s.vehicleTypeId,
      orElse: () => s.estimations.first,
    );
    return e.grossFare ?? e.totalFare + e.discount;
  }

  /// An estimate older than this is priced again before booking, so the
  /// booking never carries a code / points that stopped applying meanwhile.
  static const staleAfter = Duration(minutes: 2);

  /// Books the selected vehicle with the same code and points as the last
  /// estimate. Returns false without booking when the price had to be
  /// refreshed and changed (the customer confirms the new one), or when the
  /// backend refused the code / points (the error shows; the estimate is
  /// redone without what was refused).
  Future<DispatchOutcome> dispatchRide({
    required LatLng pickup,
    required LatLng dropoff,
    required String pickupAddress,
    required String dropoffAddress,
  }) async {
    var currentState = state.value ?? const BookingState();
    final estimatedAt = currentState.estimatedAt;
    if (estimatedAt != null &&
        DateTime.now().difference(estimatedAt) > staleAfter) {
      final before = _selected(currentState)?.payable;
      await estimateFare(
        pickup,
        dropoff,
        promoCode: currentState.appliedPromoCode,
      );
      final refreshed = state.value;
      if (refreshed == null) return DispatchOutcome.failed;
      if (_selected(refreshed)?.payable != before) {
        return DispatchOutcome.priceChanged;
      }
      currentState = refreshed;
    }

    final selected = _selected(currentState);
    // Fully paid with points: nothing to collect, so never a QR / card flow.
    final paymentMethod = (selected != null && selected.payable <= 0)
        ? 'CASH'
        : currentState.paymentMethod;
    state = const AsyncValue.loading();

    RideBooking? booking;
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(dispatchRideUseCaseProvider);
      booking = await useCase(
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        pickupAddress: pickupAddress,
        dropoffLat: dropoff.latitude,
        dropoffLng: dropoff.longitude,
        dropoffAddress: dropoffAddress,
        paymentMethod: paymentMethod,
        vehicleTypeId: currentState.vehicleTypeId,
        promoCode: currentState.appliedPromoCode,
        usePoints: currentState.usePoints ? true : null,
      );
      final code = currentState.appliedPromoCode;
      return currentState.copyWith(
        isLoading: false,
        activeJobId: booking!.id,
        error: null,
        promoDroppedOnBooking:
            code != null && booking!.promo?.applied == false,
      );
    });

    final error = state.error;
    if (error is ApiError) {
      final code = error.code ?? '';
      if (code.startsWith('REFERRAL_')) {
        // A friend's code they may not use refuses the booking: drop the code
        // and price again; they book again themselves.
        state = AsyncValue.data(currentState.copyWith(appliedPromoCode: null));
        await estimateFare(pickup, dropoff);
      } else if (code.startsWith('POINTS_')) {
        // Points changed under us (another device, a new limit, switched
        // off): price again with all that's allowed now, or without points.
        final off = code == 'POINTS_DISABLED';
        state = AsyncValue.data(
          currentState.copyWith(
            usePoints: off ? false : currentState.usePoints,
            pointsDisabled: off || currentState.pointsDisabled,
          ),
        );
        await estimateFare(
          pickup,
          dropoff,
          promoCode: currentState.appliedPromoCode,
        );
      }
      return DispatchOutcome.failed;
    }

    final booked = booking;
    if (booked == null) return DispatchOutcome.failed;
    // The welcome code is single-use: stop pre-filling it once a ride is
    // booked with it.
    await ref
        .read(welcomePromoStoreProvider)
        .consume(currentState.appliedPromoCode);
    if (booked.pointsUsed > 0) ref.invalidate(loyaltySummaryProvider);
    return DispatchOutcome.booked;
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
    if (n.contains('tuk')) {
      return 'assets/images/icons/3d/ic_car_tuktuk.png';
    }
    // economy / saver / eco and anything else → the clean sedan.
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
