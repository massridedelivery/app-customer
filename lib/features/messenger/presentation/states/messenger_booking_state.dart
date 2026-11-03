import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_estimate.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_vehicle_type.dart';
import 'package:customer_app/features/messenger/presentation/util/delivery_service_levels.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_quote.dart';
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
    // PromptPay first while it's offered; the customer can still pick cash.
    @Default(FeatureFlags.messengerPromptPayEnabled ? 'PROMPTPAY' : 'CASH')
    String paymentMethod,
    // Who pays the delivery fee: 'SENDER' (default) or 'RECIPIENT' (dev14).
    @Default('SENDER') String payer,
    @Default(0.0) double codAmount,
    @Default('') String promoCode,
    // Spend loyalty points on the fee, as on a ride (all the points allowed).
    @Default(false) bool usePoints,
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

  /// The recipient pays the fee at the door — the sender is not charged upfront,
  /// so the order dispatches straight to tracking (no PromptPay QR).
  bool get isRecipientPays => payer.toUpperCase() == 'RECIPIENT';

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

  /// Fare to display/charge for the selected delivery mode (server-computed),
  /// after the promo and, when used, the points.
  double get displayTotalFare {
    final level = selectedServiceLevel;
    if (level != null) return level.amountToPay ?? level.totalFare;
    return estimate?.amountToPay ?? estimate?.totalFare ?? 0;
  }

  /// What points can do for the selected mode, or null on an older backend.
  RidePointsQuote? get pointsQuote =>
      selectedServiceLevel?.points ?? estimate?.points;

  /// Points actually going on this booking.
  bool get spendsPoints =>
      usePoints && (pointsQuote?.usable ?? false) && pointsQuote!.usedPoints > 0;

  /// A coupon (or points) covers the whole fee. There is no QR for ฿0 (the backend won't
  /// mint one, and an unpaid PromptPay order can't be marked delivered), so
  /// such an order is placed as cash.
  bool get nothingToPay => estimate != null && displayTotalFare <= 0;
}
