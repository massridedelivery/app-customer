/// `GET /api/customer/advance-booking/config` (backend booking.AdvanceConfig):
/// whether rides may be booked ahead, the dialog to show when they may not,
/// and the rules a booking is made under. Every number is admin-set.
class AdvanceConfig {
  const AdvanceConfig({
    required this.enabled,
    this.closedTitle = '',
    this.closedMessage = '',
    this.minLeadMinutes = 30,
    this.maxDays = 7,
    this.slotMinutes = 5,
    this.freeCancelMinutes = 0,
    this.waitMinutes = 0,
    this.driverLateMinutes = 0,
    this.cashAllowed = true,
    this.maxReschedules = 0,
    this.airportWaitMinutes = 0,
    this.recurringEnabled = false,
    this.maxSeries = 0,
    this.messengerEnabled = false,
    this.preauthEnabled = false,
    this.vehicleTypes = const [],
  });

  /// Advance booking is on and some vehicle type takes it.
  final bool enabled;

  /// The admin's dialog while [enabled] is false. Never hard-coded.
  final String closedTitle;
  final String closedMessage;

  /// The shortest lead time of any bookable type: the earliest slot.
  final int minLeadMinutes;
  final int maxDays;
  final int slotMinutes;
  final int freeCancelMinutes;
  final int waitMinutes;
  final int driverLateMinutes;
  final bool cashAllowed;
  final int maxReschedules;
  final int airportWaitMinutes;
  final bool recurringEnabled;
  final int maxSeries;
  final bool messengerEnabled;
  final bool preauthEnabled;
  final List<AdvanceVehicleType> vehicleTypes;

  /// The ride (not parcel) types. Parcel types say vehicle_class `messenger`.
  List<AdvanceVehicleType> get rideTypes =>
      vehicleTypes.where((v) => v.vehicleClass != 'messenger').toList();

  AdvanceVehicleType? typeById(String id) =>
      vehicleTypes.where((v) => v.vehicleTypeId == id).firstOrNull;

  factory AdvanceConfig.fromJson(Map<String, dynamic> json) {
    int i(String k, int fallback) {
      final v = json[k];
      return v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
    }

    String s(String k) => (json[k] ?? '').toString().trim();
    return AdvanceConfig(
      enabled: json['enabled'] == true,
      closedTitle: s('closed_title'),
      closedMessage: s('closed_message'),
      minLeadMinutes: i('min_lead_minutes', 30),
      maxDays: i('max_days', 7),
      // A slot of 0 would make an endless wheel; 5 minutes is the default.
      slotMinutes: i('slot_minutes', 5) <= 0 ? 5 : i('slot_minutes', 5),
      freeCancelMinutes: i('free_cancel_minutes', 0),
      waitMinutes: i('wait_minutes', 0),
      driverLateMinutes: i('driver_late_minutes', 0),
      cashAllowed: json['cash_allowed'] != false,
      maxReschedules: i('max_reschedules', 0),
      airportWaitMinutes: i('airport_wait_minutes', 0),
      recurringEnabled: json['recurring_enabled'] == true,
      maxSeries: i('max_series', 0),
      messengerEnabled: json['messenger_enabled'] == true,
      preauthEnabled: json['preauth_enabled'] == true,
      vehicleTypes: json['vehicle_types'] is List
          ? (json['vehicle_types'] as List)
                .whereType<Map>()
                .map(
                  (m) =>
                      AdvanceVehicleType.fromJson(Map<String, dynamic>.from(m)),
                )
                .toList()
          : const [],
    );
  }
}

/// One vehicle type that takes advance bookings, with its own rules.
class AdvanceVehicleType {
  const AdvanceVehicleType({
    required this.vehicleTypeId,
    this.displayName = '',
    this.vehicleKind = '',
    this.vehicleClass = '',
    this.fee = 0,
    this.minLeadMinutes = 0,
    this.lateCancelFee = 0,
    this.searchStartsMinutesBefore = 0,
  });

  final String vehicleTypeId;
  final String displayName;
  final String vehicleKind;

  /// `messenger` for a parcel type; empty on older backends.
  final String vehicleClass;

  /// The advance booking fee (a promo never discounts it).
  final double fee;
  final int minLeadMinutes;
  final double lateCancelFee;
  final int searchStartsMinutesBefore;

  factory AdvanceVehicleType.fromJson(Map<String, dynamic> json) {
    double d(String k) {
      final v = json[k];
      return v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    }

    int i(String k) {
      final v = json[k];
      return v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    }

    return AdvanceVehicleType(
      vehicleTypeId: (json['vehicle_type_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      vehicleKind: (json['vehicle_kind'] ?? '').toString(),
      vehicleClass: (json['vehicle_class'] ?? '').toString(),
      fee: d('advance_booking_fee'),
      minLeadMinutes: i('min_lead_minutes'),
      lateCancelFee: d('late_cancel_fee'),
      searchStartsMinutesBefore: i('search_starts_minutes_before'),
    );
  }
}

/// `GET /api/customer/advance-booking/options`: one vehicle type's locked
/// price for the trip at the chosen time (backend booking.AdvanceOption).
class AdvanceOption {
  const AdvanceOption({
    required this.type,
    required this.fare,
    required this.rideFare,
    required this.bookable,
    this.reason,
    this.seats,
    this.freeCancelUntil,
  });

  final AdvanceVehicleType type;

  /// The locked price: the fare without surge plus the advance booking fee.
  final double fare;

  /// [fare] without the advance booking fee.
  final double rideFare;
  final bool bookable;

  /// TOO_SOON | TOO_FAR when [bookable] is false.
  final String? reason;
  final int? seats;

  /// Once a driver has it, cancelling is free until then (UTC).
  final DateTime? freeCancelUntil;

  factory AdvanceOption.fromJson(Map<String, dynamic> json) {
    double d(String k) {
      final v = json[k];
      return v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    }

    final reason = (json['reason'] ?? '').toString();
    final seats = json['seats'];
    return AdvanceOption(
      type: AdvanceVehicleType.fromJson(json),
      fare: d('fare'),
      rideFare: d('ride_fare'),
      bookable: json['bookable'] != false,
      reason: reason.isEmpty ? null : reason,
      seats: seats is num ? seats.toInt() : null,
      freeCancelUntil: DateTime.tryParse(
        '${json['free_cancel_until'] ?? ''}',
      )?.toUtc(),
    );
  }

  /// The options of a `GET …/options` body (`{options: [...]}`).
  static List<AdvanceOption> listFrom(Object? body) {
    final list = body is Map ? body['options'] : null;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => AdvanceOption.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}
