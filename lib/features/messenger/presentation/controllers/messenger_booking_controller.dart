import 'dart:async';

import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_vehicle_type.dart';
import 'package:customer_app/features/messenger/presentation/states/messenger_booking_state.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messenger_booking_controller.g.dart';

@riverpod
class MessengerBookingController extends _$MessengerBookingController {
  Timer? _estimateDebounce;

  @override
  MessengerBookingState build() {
    // Pickup/dropoff live on the shared home place stack; re-quote whenever
    // the user comes back from the pin-selection screens.
    ref.listen(homeControllerProvider, (previous, next) {
      if (previous?.pickupLocation != next.pickupLocation ||
          previous?.dropoffLocation != next.dropoffLocation) {
        _scheduleEstimate();
      }
    });
    ref.onDispose(() => _estimateDebounce?.cancel());
    Future.microtask(loadVehicleTypes);
    return const MessengerBookingState(isLoadingVehicles: true);
  }

  Future<void> loadVehicleTypes() async {
    state = state.copyWith(isLoadingVehicles: true, error: null);
    try {
      final vehicles =
          await ref.read(messengerRepositoryProvider).getMessengerVehicleTypes();
      final first = vehicles.isEmpty ? null : vehicles.first;
      state = state.copyWith(
        isLoadingVehicles: false,
        vehicleTypes: vehicles,
        vehicleTypeId: first?.id ?? '',
        // Reconcile the default tier ('S') to the loaded vehicle's real tiers,
        // otherwise selectedSizeTier stays null and the estimate never fires.
        sizeTier: _validTierFor(first, state.sizeTier),
      );
      _scheduleEstimate();
    } catch (e) {
      state = state.copyWith(
        isLoadingVehicles: false,
        error: 'โหลดประเภทรถไม่สำเร็จ กรุณาลองใหม่',
      );
      debugPrint('MessengerBookingController.loadVehicleTypes: $e');
    }
  }

  void selectVehicle(String vehicleTypeId) {
    if (vehicleTypeId == state.vehicleTypeId) return;
    final matches =
        state.vehicleTypes.where((e) => e.id == vehicleTypeId).toList();
    final v = matches.isEmpty ? null : matches.first;
    state = state.copyWith(
      vehicleTypeId: vehicleTypeId,
      sizeTier: _validTierFor(v, state.sizeTier),
      estimate: null,
    );
    _scheduleEstimate();
  }

  /// Keeps the current tier if the vehicle offers it, otherwise falls back to
  /// the vehicle's first tier (or the current value when tiers are unknown).
  String _validTierFor(MessengerVehicleType? vehicle, String current) {
    if (vehicle == null || vehicle.sizeTiers.isEmpty) return current;
    final hasCurrent = vehicle.sizeTiers.any(
      (t) => t.tier.toUpperCase() == current.toUpperCase(),
    );
    return hasCurrent ? current : vehicle.sizeTiers.first.tier;
  }

  void selectSizeTier(String tier) {
    if (tier == state.sizeTier) return;
    state = state.copyWith(sizeTier: tier, estimate: null);
    _scheduleEstimate();
  }

  void setWeight(double weightKg) {
    state = state.copyWith(weightKg: weightKg);
    _scheduleEstimate();
  }

  void setDimensions({double? lengthCm, double? widthCm, double? heightCm}) {
    state = state.copyWith(
      lengthCm: lengthCm,
      widthCm: widthCm,
      heightCm: heightCm,
    );
    _scheduleEstimate();
  }

  /// Pick the delivery mode (INSTANT / TWO_HOUR). STOPGAP: no re-estimate is
  /// needed — [MessengerBookingState.displayTotalFare] derives the per-mode
  /// price from the existing estimate until BE ships `service_levels[]`
  /// (SCRUM-71), at which point this should trigger a re-estimate instead.
  void selectDeliveryType(String type) {
    if (type == state.deliveryType) return;
    state = state.copyWith(deliveryType: type);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// 'SENDER' (default) | 'RECIPIENT' (dev14).
  void setPayer(String payer) {
    if (payer == state.payer) return;
    state = state.copyWith(payer: payer);
  }

  void setCodAmount(double amount) {
    state = state.copyWith(codAmount: amount);
  }

  void setPromoCode(String code) {
    if (code == state.promoCode) return;
    state = state.copyWith(promoCode: code);
    _scheduleEstimate();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// All estimate preconditions satisfied (dropoff picked, package fits tier).
  bool get _canEstimate {
    final home = ref.read(homeControllerProvider);
    final tier = state.selectedSizeTier;
    if (home.pickupLocation == null || home.dropoffLocation == null) {
      return false;
    }
    if (state.vehicleTypeId.isEmpty || tier == null) return false;
    if (state.weightKg <= 0 || state.weightKg > tier.maxWeightKg) return false;
    if ((state.lengthCm ?? 0) > tier.maxLengthCm && tier.maxLengthCm > 0) {
      return false;
    }
    if ((state.widthCm ?? 0) > tier.maxWidthCm && tier.maxWidthCm > 0) {
      return false;
    }
    if ((state.heightCm ?? 0) > tier.maxHeightCm && tier.maxHeightCm > 0) {
      return false;
    }
    return true;
  }

  void _scheduleEstimate() {
    _estimateDebounce?.cancel();
    _estimateDebounce = Timer(const Duration(milliseconds: 450), estimate);
  }

  Future<void> estimate() async {
    if (!_canEstimate) {
      state = state.copyWith(estimate: null, isEstimating: false);
      return;
    }
    final home = ref.read(homeControllerProvider);
    state = state.copyWith(isEstimating: true, error: null);
    try {
      final result = await ref.read(messengerRepositoryProvider).estimate(
            vehicleTypeId: state.vehicleTypeId,
            pickupLat: home.pickupLocation!.latitude,
            pickupLng: home.pickupLocation!.longitude,
            dropoffLat: home.dropoffLocation!.latitude,
            dropoffLng: home.dropoffLocation!.longitude,
            packageSizeTier: state.sizeTier,
            packageWeightKg: state.weightKg,
            packageLengthCm: state.lengthCm,
            packageWidthCm: state.widthCm,
            packageHeightCm: state.heightCm,
            promoCode: state.promoCode,
            deliveryType: state.deliveryType,
          );
      // Keep the selection valid: if the chosen mode was disabled by admin (not
      // in the returned service_levels), fall back to the first offered mode.
      final levels = result.serviceLevels;
      final validType =
          levels.any((l) => l.deliveryType == state.deliveryType)
          ? state.deliveryType
          : (levels.isNotEmpty ? levels.first.deliveryType : state.deliveryType);
      state = state.copyWith(
        isEstimating: false,
        estimate: result,
        deliveryType: validType,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isEstimating: false,
        estimate: null,
        error: msg == 'NO_DELIVERY_MODES'
            ? 'ขณะนี้ยังไม่เปิดให้บริการจัดส่ง กรุณาลองใหม่ภายหลัง'
            : msg,
      );
    }
  }

  Future<void> createOrder({
    String? recipientName,
    String? recipientPhone,
    String? notes,
  }) async {
    if (!_canEstimate || state.isCreating) return;
    final home = ref.read(homeControllerProvider);
    state = state.copyWith(isCreating: true, error: null);
    try {
      final order = await ref.read(messengerRepositoryProvider).createOrder(
            vehicleTypeId: state.vehicleTypeId,
            pickupLat: home.pickupLocation!.latitude,
            pickupLng: home.pickupLocation!.longitude,
            dropoffLat: home.dropoffLocation!.latitude,
            dropoffLng: home.dropoffLocation!.longitude,
            packageSizeTier: state.sizeTier,
            packageWeightKg: state.weightKg,
            paymentMethod: state.paymentMethod,
            deliveryType: state.deliveryType,
            pickupAddress: home.pickupAddress,
            dropoffAddress: home.dropoffAddress,
            recipientName: recipientName,
            recipientPhone: recipientPhone,
            notes: notes,
            packageLengthCm: state.lengthCm,
            packageWidthCm: state.widthCm,
            packageHeightCm: state.heightCm,
            codAmount: state.isCod ? state.codAmount : null,
            promoCode: state.promoCode,
            payer: state.payer,
          );
      state = state.copyWith(isCreating: false, createdOrderId: order.id);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'DELIVERY_MODE_UNAVAILABLE') {
        // The selected mode was disabled while the user waited — re-estimate so
        // the picker reflects the currently-offered modes, and prompt a retry.
        state = state.copyWith(
          isCreating: false,
          error: 'โหมดจัดส่งที่เลือกถูกปิด กรุณาเลือกใหม่แล้วลองอีกครั้ง',
        );
        unawaited(estimate());
      } else {
        state = state.copyWith(isCreating: false, error: msg);
      }
    }
  }
}
