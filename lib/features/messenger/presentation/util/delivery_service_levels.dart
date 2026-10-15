/// Delivery-mode helpers for the messenger booking flow.
///
/// The service levels themselves now come from the backend
/// (`estimate.service_levels[]`, SCRUM-71) as [MessengerServiceLevel]; this file
/// only keeps the mode identifiers and a small time formatter.
library;

/// Delivery-mode identifiers (match the backend `delivery_type` enum).
const String kDeliveryInstant = 'INSTANT';
const String kDeliveryTwoHour = 'TWO_HOUR';

/// A backend `deliver_by` ISO8601 timestamp in device-local time.
/// Returns null when [iso] is null/blank/unparseable.
DateTime? parseDeliverBy(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  return DateTime.tryParse(iso)?.toLocal();
}
