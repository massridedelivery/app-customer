import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/advance_booking/domain/advance_config.dart';
import 'package:customer_app/features/advance_booking/domain/advance_refusal.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One advance booking being put together: the pickup time, the priced
/// vehicle types for it, the chosen one, payment, promo code and flight. The
/// route is the home screen's pickup / dropoff, as in the normal booking.
class AdvanceBookingState {
  const AdvanceBookingState({
    this.scheduledAt,
    this.options = const AsyncData(<AdvanceOption>[]),
    this.selectedTypeId,
    this.paymentMethod = 'PROMPTPAY',
    this.promoCode,
    this.flightNumber = '',
    this.submitting = false,
    this.distanceKm,
    this.durationMin,
  });

  /// The pickup time (UTC); null until the customer picks one.
  final DateTime? scheduledAt;
  final AsyncValue<List<AdvanceOption>> options;
  final String? selectedTypeId;
  final String paymentMethod;
  final String? promoCode;
  final String flightNumber;
  final bool submitting;

  /// The trip the options were priced for; null when the server didn't say.
  final double? distanceKm;
  final double? durationMin;

  AdvanceOption? get selected => options.value
      ?.where((o) => o.type.vehicleTypeId == selectedTypeId)
      .firstOrNull;

  AdvanceBookingState copyWith({
    DateTime? scheduledAt,
    AsyncValue<List<AdvanceOption>>? options,
    String? Function()? selectedTypeId,
    String? paymentMethod,
    String? Function()? promoCode,
    String? flightNumber,
    bool? submitting,
    double? Function()? distanceKm,
    double? Function()? durationMin,
  }) => AdvanceBookingState(
    scheduledAt: scheduledAt ?? this.scheduledAt,
    options: options ?? this.options,
    selectedTypeId: selectedTypeId != null
        ? selectedTypeId()
        : this.selectedTypeId,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    promoCode: promoCode != null ? promoCode() : this.promoCode,
    flightNumber: flightNumber ?? this.flightNumber,
    submitting: submitting ?? this.submitting,
    distanceKm: distanceKm != null ? distanceKm() : this.distanceKm,
    durationMin: durationMin != null ? durationMin() : this.durationMin,
  );
}

final advanceBookingControllerProvider =
    NotifierProvider.autoDispose<AdvanceBookingController, AdvanceBookingState>(
      AdvanceBookingController.new,
    );

class AdvanceBookingController extends Notifier<AdvanceBookingState> {
  @override
  AdvanceBookingState build() => const AdvanceBookingState();

  /// A new pickup time: price the trip for it.
  Future<void> setTime(DateTime at) async {
    state = state.copyWith(scheduledAt: at.toUtc());
    await loadOptions();
  }

  /// GET …/advance-booking/options for the current route and time. Keeps the
  /// chosen type when it is still bookable, else picks the first that is.
  Future<void> loadOptions() async {
    final at = state.scheduledAt;
    final home = ref.read(homeControllerProvider);
    final pickup = home.pickupLocation;
    final dropoff = home.dropoffLocation;
    if (at == null || pickup == null || dropoff == null) return;
    state = state.copyWith(options: const AsyncLoading());
    try {
      final body = await ref
          .read(apiRepositoryProvider)
          .getAdvanceOptions(
            pickupLat: pickup.latitude,
            pickupLng: pickup.longitude,
            dropoffLat: dropoff.latitude,
            dropoffLng: dropoff.longitude,
            scheduledAt: at,
          );
      if (!ref.mounted) return;
      final options = AdvanceOption.listFrom(body);
      final keep = options
          .where(
            (o) => o.bookable && o.type.vehicleTypeId == state.selectedTypeId,
          )
          .firstOrNull;
      final first = options.where((o) => o.bookable).firstOrNull;
      final trip = AdvanceOption.tripFrom(body);
      state = state.copyWith(
        options: AsyncData(options),
        distanceKm: () => trip.distanceKm,
        durationMin: () => trip.durationMin,
        selectedTypeId: () => (keep ?? first)?.type.vehicleTypeId,
      );
    } catch (e, st) {
      if (!ref.mounted) return;
      state = state.copyWith(options: AsyncError(e, st));
    }
  }

  void select(String vehicleTypeId) =>
      state = state.copyWith(selectedTypeId: () => vehicleTypeId);

  void setPaymentMethod(String method) =>
      state = state.copyWith(paymentMethod: method);

  void setPromoCode(String? code) {
    final c = code?.trim().toUpperCase();
    state = state.copyWith(
      promoCode: () => (c == null || c.isEmpty) ? null : c,
    );
  }

  void setFlightNumber(String flight) =>
      state = state.copyWith(flightNumber: flight.trim());

  /// The POST /jobs/schedule body: the same as POST /jobs, plus scheduled_at
  /// and, for an airport pickup, flight_number.
  Map<String, dynamic>? requestBody() {
    final home = ref.read(homeControllerProvider);
    final pickup = home.pickupLocation;
    final dropoff = home.dropoffLocation;
    final at = state.scheduledAt;
    final option = state.selected;
    if (pickup == null || dropoff == null || at == null || option == null) {
      return null;
    }
    final flight = state.flightNumber.trim();
    return {
      'pickup_lat': pickup.latitude,
      'pickup_lng': pickup.longitude,
      'pickup_address': home.pickupAddress ?? '',
      'dropoff_lat': dropoff.latitude,
      'dropoff_lng': dropoff.longitude,
      'dropoff_address': home.dropoffAddress ?? '',
      'payment_method': state.paymentMethod,
      'vehicle_type_id': option.type.vehicleTypeId,
      'promo_code': ?state.promoCode,
      'scheduled_at': at.toUtc().toIso8601String(),
      if (flight.isNotEmpty) 'flight_number': flight,
    };
  }

  /// POST /api/customer/jobs/schedule. Returns the booked job; throws an
  /// [AdvanceRefusal] for a 422 with a code, else the original error.
  Future<Map<String, dynamic>> submit() async {
    final body = requestBody();
    if (body == null) {
      throw const AdvanceRefusal(AdvanceRefusalKind.unknown);
    }
    state = state.copyWith(submitting: true);
    try {
      return await ref.read(apiRepositoryProvider).scheduleJob(body);
    } catch (e) {
      throw AdvanceRefusal.from(e) ?? e;
    } finally {
      if (ref.mounted) state = state.copyWith(submitting: false);
    }
  }
}
