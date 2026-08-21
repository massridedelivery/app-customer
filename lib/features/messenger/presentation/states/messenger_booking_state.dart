import 'package:customer_app/features/messenger/domain/models/messenger_estimate.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_vehicle_type.dart';
import 'package:customer_app/features/messenger/presentation/util/delivery_service_levels.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'messenger_booking_state.freezed.dart';

@freezed
abstract class MessengerBookingState with _$MessengerBookingState {
  const MessengerBookingState._();

  const factory MessengerBookingState({
    @Default(false) bool isLoadingVehicles,
    @Default([]) List<MessengerVehicleType> vehicleTypes,
    @Default('') String vehicleTypeId,
    @Default('S') String sizeTier,
    @Default(0.0) double weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    @Default('CASH') String paymentMethod,
    @Default(0.0) double codAmount,
    @Default('') String promoCode,
    // Selected delivery mode (delivery_type, e.g. INSTANT / TWO_HOUR). The
    // available modes + pricing come from estimate.serviceLevels (SCRUM-71).
    @Default(kDeliveryInstant) String deliveryType,
    MessengerEstimate? estimate,
    @Default(false) bool isEstimating,
    @Default(false) bool isCreating,
    String? error,
    String? createdOrderId,
  }) = _MessengerBookingState;

  MessengerVehicleType? get selectedVehicle {
    final matches = vehicleTypes.where((v) => v.id == vehicleTypeId).toList();
    return matches.isEmpty ? null : matches.first;
  }

  MessengerSizeTier? get selectedSizeTier {
    final vehicle = selectedVehicle;
    if (vehicle == null) return null;
    final matches = vehicle.sizeTiers
        .where((t) => t.tier.toUpperCase() == sizeTier.toUpperCase())
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  bool get isCod => paymentMethod.toUpperCase() == 'COD';

  /// Delivery modes offered by the backend for the current estimate.
  List<MessengerServiceLevel> get serviceLevels =>
      estimate?.serviceLevels ?? const [];

  /// The service level matching [deliveryType], else the first available one
  /// (so a disabled/absent selection falls back to a real offered mode).
  MessengerServiceLevel? get selectedServiceLevel {
    final levels = serviceLevels;
    if (levels.isEmpty) return null;
    for (final l in levels) {
      if (l.deliveryType == deliveryType) return l;
    }
    return levels.first;
  }

  /// Fare to display/charge for the selected delivery mode (server-computed).
  double get displayTotalFare =>
      selectedServiceLevel?.totalFare ?? estimate?.totalFare ?? 0;
}
