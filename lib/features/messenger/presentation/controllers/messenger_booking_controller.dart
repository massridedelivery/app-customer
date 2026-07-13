import 'dart:async';

import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/messenger/data/repositories/messenger_repository_impl.dart';
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
      state = state.copyWith(
        isLoadingVehicles: false,
        vehicleTypes: vehicles,
        vehicleTypeId: vehicles.isNotEmpty ? vehicles.first.id : '',
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
    state = state.copyWith(vehicleTypeId: vehicleTypeId, estimate: null);
    _scheduleEstimate();
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

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
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
          );
      state = state.copyWith(isEstimating: false, estimate: result);
    } catch (e) {
      state = state.copyWith(
        isEstimating: false,
        estimate: null,
        error: e.toString().replaceFirst('Exception: ', ''),
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
          );
      state = state.copyWith(isCreating: false, createdOrderId: order.id);
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
