/// Delivery-mode helpers for the messenger booking flow.
///
/// The service levels themselves now come from the backend
/// (`estimate.service_levels[]`, SCRUM-71) as [MessengerServiceLevel]; this file
/// only keeps the mode identifiers and a small time formatter.
library;

/// Delivery-mode identifiers (match the backend `delivery_type` enum).
const String kDeliveryInstant = 'INSTANT';
const String kDeliveryTwoHour = 'TWO_HOUR';

/// Format a backend `deliver_by` ISO8601 timestamp as a local HH:mm clock.
/// Returns null when [iso] is null/blank/unparseable.
String? formatDeliverBy(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return null;
  return '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}
