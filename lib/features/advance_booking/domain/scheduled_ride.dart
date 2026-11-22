/// A ride booked ahead (งานจองล่วงหน้า), as `GET /api/customer/jobs/scheduled`
/// returns it (backend job.Job: scheduled_at, advance_booking_fee,
/// advance_policy, advance_phase, driver_id, reserved_driver_id).
class ScheduledRide {
  const ScheduledRide({
    required this.id,
    required this.status,
    this.scheduledAt,
    this.pickupAddress = '',
    this.dropoffAddress = '',
    this.fare = 0,
    this.advanceFee = 0,
    this.driverId,
    this.reservedDriverId,
    this.phase,
    this.freeCancelMinutes,
    this.lateCancelFee = 0,
    this.waitMinutes,
    this.flightNumber,
    this.freeCancelUntilFromApi,
    this.reschedulesLeft,
    this.minLeadMinutes,
    this.paymentMethod = '',
    this.vehicleTypeId,
    this.driverName,
    this.vehicleName,
    this.vehiclePlate,
    this.vehicleDescription,
  });

  final String id;
  final String status;

  /// Pickup time (UTC instant).
  final DateTime? scheduledAt;
  final String pickupAddress;
  final String dropoffAddress;

  /// The locked price, the advance booking fee included.
  final double fare;
  final double advanceFee;
  final String? driverId;
  final String? reservedDriverId;

  /// advance_phase, as the backend names where the booking is.
  final String? phase;
  final int? freeCancelMinutes;
  final double lateCancelFee;
  final int? waitMinutes;
  final String? flightNumber;

  /// free_cancel_until, once the backend sends it.
  final DateTime? freeCancelUntilFromApi;

  /// How many more times it can be moved (0 once a driver has it or the
  /// search started); null when the backend didn't say.
  final int? reschedulesLeft;

  /// The lead time the ride was booked under (advance_policy): a new time
  /// must be at least this far ahead.
  final int? minLeadMinutes;
  final String paymentMethod;
  final String? vehicleTypeId;

  /// The driver (driver_info), once one has the ride.
  final String? driverName;

  /// The vehicle type's display name, when the backend sends it.
  final String? vehicleName;
  final String? vehiclePlate;

  /// "Toyota Altis สีขาว".
  final String? vehicleDescription;

  /// The fare without the advance booking fee.
  double get rideFare => (fare - advanceFee) < 0 ? fare : fare - advanceFee;

  /// The search for a driver has started (DISPATCHING) or the ride is live.
  bool get searchStarted =>
      phase == 'DISPATCHING' || phase == 'LIVE' || status != 'PENDING';

  /// "เลื่อนเวลา" is offered: no driver, the search not started, and moves
  /// left (when known).
  bool get canReschedule =>
      !hasDriver &&
      !searchStarted &&
      (reschedulesLeft == null || reschedulesLeft! > 0);

  /// A driver has taken it (or is reserved for it).
  bool get hasDriver =>
      (driverId?.isNotEmpty ?? false) ||
      (reservedDriverId?.isNotEmpty ?? false);

  /// Free cancelling ends here: the backend's free_cancel_until, else
  /// scheduled_at − advance_policy.free_cancel_minutes. Null when unknown.
  DateTime? get freeCancelUntil {
    if (freeCancelUntilFromApi != null) return freeCancelUntilFromApi;
    final at = scheduledAt;
    final m = freeCancelMinutes;
    if (at == null || m == null) return null;
    return at.subtract(Duration(minutes: m));
  }

  factory ScheduledRide.fromJson(Map<String, dynamic> json) {
    String? str(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    double num0(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    int? intOrNull(Object? v) => v is num ? v.toInt() : int.tryParse('$v');
    DateTime? time(Object? v) =>
        v == null ? null : DateTime.tryParse('$v')?.toUtc();

    final driver = json['driver_info'] is Map
        ? Map<String, dynamic>.from(json['driver_info'] as Map)
        : const <String, dynamic>{};
    final policy = json['advance_policy'] is Map
        ? Map<String, dynamic>.from(json['advance_policy'] as Map)
        : const <String, dynamic>{};
    return ScheduledRide(
      id: str(json['id']) ?? '',
      status: (str(json['status']) ?? '').toUpperCase(),
      scheduledAt: time(json['scheduled_at']),
      pickupAddress: str(json['pickup_address']) ?? '',
      dropoffAddress: str(json['dropoff_address']) ?? '',
      fare: num0(json['fare']),
      advanceFee: num0(json['advance_booking_fee']),
      driverId: str(json['driver_id']),
      reservedDriverId: str(json['reserved_driver_id']),
      phase: str(json['advance_phase']),
      freeCancelMinutes: intOrNull(policy['free_cancel_minutes']),
      lateCancelFee: num0(policy['late_cancel_fee']),
      waitMinutes: intOrNull(policy['wait_minutes']),
      flightNumber: str(policy['flight_number']),
      freeCancelUntilFromApi: time(json['free_cancel_until']),
      reschedulesLeft: json['reschedules_left'] == null
          ? null
          : intOrNull(json['reschedules_left']),
      minLeadMinutes: intOrNull(policy['min_lead_minutes']),
      paymentMethod: (str(json['payment_method']) ?? '').toUpperCase(),
      vehicleTypeId: str(json['vehicle_type_id']),
      driverName: str(driver['full_name']),
      vehicleName:
          str(driver['vehicle_type_display_name']) ??
          str(json['vehicle_type_display_name']),
      vehiclePlate: str(driver['vehicle_plate']),
      vehicleDescription: str(
        [
          str(driver['vehicle_model']),
          str(driver['vehicle_color']),
        ].whereType<String>().join(' '),
      ),
    );
  }
}

/// GET …/jobs/scheduled/{id}/cancel-quote (backend job.CancellationQuote).
class ScheduledCancelQuote {
  const ScheduledCancelQuote({required this.isFree, this.fee = 0, this.reason});

  final bool isFree;
  final double fee;

  /// NO_DRIVER_YET | BEFORE_FREE_CANCEL_TIME | DRIVER_LATE | LATE_CANCEL.
  final String? reason;

  factory ScheduledCancelQuote.fromJson(Map<String, dynamic> json) {
    final fee = json['cancellation_fee'];
    final reason = json['reason']?.toString();
    return ScheduledCancelQuote(
      isFree: json['is_free'] == true,
      fee: fee is num ? fee.toDouble() : 0,
      reason: reason == null || reason.isEmpty ? null : reason,
    );
  }
}

/// A repeating booking (จองซ้ำ), `GET /api/customer/advance-series`.
class AdvanceSeries {
  const AdvanceSeries({
    required this.id,
    required this.status,
    this.time = '',
    this.weekdays = const [],
    this.pickupAddress = '',
    this.dropoffAddress = '',
    this.lastError,
    this.lastErrorOn,
    this.upcoming = const [],
  });

  final String id;

  /// ACTIVE | PAUSED.
  final String status;

  /// HH:MM, Bangkok.
  final String time;

  /// 1 Monday … 7 Sunday.
  final List<int> weekdays;
  final String pickupAddress;
  final String dropoffAddress;

  /// Why the latest day could not be booked (a booking refusal code).
  final String? lastError;
  final String? lastErrorOn;
  final List<SeriesDay> upcoming;

  factory AdvanceSeries.fromJson(Map<String, dynamic> json) {
    String? str(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final req = json['request'] is Map
        ? Map<String, dynamic>.from(json['request'] as Map)
        : const <String, dynamic>{};
    return AdvanceSeries(
      id: str(json['id']) ?? '',
      status: (str(json['status']) ?? '').toUpperCase(),
      time: str(json['time']) ?? '',
      weekdays: json['weekdays'] is List
          ? (json['weekdays'] as List)
                .whereType<num>()
                .map((n) => n.toInt())
                .toList()
          : const [],
      pickupAddress: str(req['pickup_address']) ?? '',
      dropoffAddress: str(req['dropoff_address']) ?? '',
      lastError: str(json['last_error']),
      lastErrorOn: str(json['last_error_on']),
      upcoming: json['upcoming'] is List
          ? (json['upcoming'] as List)
                .whereType<Map>()
                .map((m) => SeriesDay.fromJson(Map<String, dynamic>.from(m)))
                .toList()
          : const [],
    );
  }
}

/// One booked day of a series.
class SeriesDay {
  const SeriesDay({
    required this.jobId,
    required this.date,
    this.scheduledAt,
    this.status = '',
  });

  final String jobId;
  final String date;
  final DateTime? scheduledAt;
  final String status;

  factory SeriesDay.fromJson(Map<String, dynamic> json) => SeriesDay(
    jobId: '${json['job_id'] ?? ''}',
    date: '${json['date'] ?? ''}',
    scheduledAt: DateTime.tryParse('${json['scheduled_at'] ?? ''}')?.toUtc(),
    status: '${json['status'] ?? ''}'.toUpperCase(),
  );
}
