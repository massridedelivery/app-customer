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
