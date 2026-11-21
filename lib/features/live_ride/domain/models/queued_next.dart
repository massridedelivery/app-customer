/// Back-to-back dispatch (งานต่อเนื่อง): while a ride is still PENDING, a
/// driver finishing a trip nearby has queued it as their next one. From the
/// `job_queued` socket frame and `queued_next` on GET /api/customer/jobs/:id
/// and /jobs/active (backend job.QueuedNext: driver_id, driver_info, eta_min,
/// arrive_by). Cancelling stays free while queued.
class QueuedNext {
  const QueuedNext({
    required this.driverId,
    this.driverName = '',
    this.avatarUrl = '',
    this.rating = 0,
    this.vehiclePlate = '',
    this.vehicleProvince = '',
    this.vehicleModel = '',
    this.vehicleColor = '',
    this.etaMin,
    this.arriveBy,
  });

  final String driverId;
  final String driverName;
  final String avatarUrl;
  final double rating;
  final String vehiclePlate;
  final String vehicleProvince;
  final String vehicleModel;
  final String vehicleColor;

  /// Minutes to the pickup, the driver's current trip included.
  final int? etaMin;

  /// When the ride goes back to dispatch if the driver has not come.
  final DateTime? arriveBy;

  /// Null when [json] isn't a queued driver (no driver_id).
  static QueuedNext? fromJson(Object? json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final id = m['driver_id']?.toString() ?? '';
    if (id.isEmpty) return null;
    final info = m['driver_info'] is Map
        ? Map<String, dynamic>.from(m['driver_info'] as Map)
        : const <String, dynamic>{};
    String s(Object? v) => v?.toString() ?? '';
    final eta = m['eta_min'];
    final rating = info['rating'];
    return QueuedNext(
      driverId: id,
      driverName: s(info['full_name']),
      avatarUrl: s(info['avatar_url']),
      rating: rating is num ? rating.toDouble() : 0,
      vehiclePlate: s(info['vehicle_plate']),
      vehicleProvince: s(info['vehicle_province']),
      vehicleModel: s(info['vehicle_model']),
      vehicleColor: s(info['vehicle_color']),
      etaMin: eta is num ? eta.round() : int.tryParse(s(eta)),
      arriveBy: DateTime.tryParse(s(m['arrive_by'])),
    );
  }
}
