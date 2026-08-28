/// Whether a service (ride/messenger) is live at a given location, plus the
/// human-readable area name to show the customer (SCRUM zone-availability API).
class ServiceAreaResult {
  final bool available;
  final String areaName;
  final String? message;

  const ServiceAreaResult({
    required this.available,
    this.areaName = '',
    this.message,
  });

  /// Fail-open default: used when the backend can't be reached or hasn't
  /// shipped the endpoint yet, so the booking flow is never blocked prematurely.
  static const ServiceAreaResult openFallback =
      ServiceAreaResult(available: true);

  factory ServiceAreaResult.fromJson(Map<String, dynamic> json) {
    return ServiceAreaResult(
      // Absent/unparseable `available` is treated as open (fail-open).
      available: json['available'] != false,
      areaName: (json['area_name'] ?? json['areaName'] ?? '').toString(),
      message: json['message']?.toString(),
    );
  }
}
