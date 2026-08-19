/// STOPGAP — client-side delivery service levels for the messenger booking flow.
///
/// The backend does not yet expose delivery modes, per-mode pricing, or a
/// server-computed `deliver_by` time (tracked in SCRUM-71). Until it does we
/// synthesise the two modes on the client so the UI can ship. When BE lands
/// `service_levels[]` on the estimate response, replace [stopgapServiceLevels]
/// and [stopgapTotalFor] with straight parsing of those fields and delete the
/// `kStopgap*` constants below — the widgets consume [MessengerServiceLevel]
/// and the state's delivery type, so no UI change is needed at swap time.
library;

import 'package:customer_app/features/messenger/domain/models/messenger_estimate.dart';

/// Delivery-mode identifiers. Match the enum proposed to BE in SCRUM-71.
const String kDeliveryInstant = 'INSTANT';
const String kDeliveryTwoHour = 'TWO_HOUR';

/// STOPGAP: the 2-hour tier is priced a flat fraction below the (fast) instant
/// price. Real per-mode pricing + the admin-configurable express surcharge come
/// from BE (SCRUM-71); this factor only keeps the preview coherent meanwhile.
const double kStopgapTwoHourFactor = 0.85;

/// STOPGAP windows (minutes). BE will send `pickup_eta_min` + `deliver_by`.
const int kStopgapPickupEtaMin = 60;
const int kStopgapTwoHourWindowMin = 120;
const double kStopgapInstantTravelFallbackMin = 30;

/// One selectable delivery mode as shown in the booking UI.
class MessengerServiceLevel {
  const MessengerServiceLevel({
    required this.type,
    required this.title,
    required this.pickupEtaMin,
    required this.deliverBy,
    required this.totalFare,
    required this.hasPrice,
  });

  final String type;
  final String title;
  final int pickupEtaMin;
  final DateTime deliverBy;
  final double totalFare;

  /// False before an estimate is available — the UI shows a placeholder price.
  final bool hasPrice;

  bool get isInstant => type == kDeliveryInstant;
}

/// STOPGAP total for [type] given the current single-price [estimate].
/// Instant keeps the BE estimate as-is (today's charged price); the 2-hour tier
/// is discounted by [kStopgapTwoHourFactor].
double stopgapTotalFor(MessengerEstimate? estimate, String type) {
  final base = estimate?.totalFare ?? 0;
  if (base <= 0) return 0;
  return type == kDeliveryTwoHour ? base * kStopgapTwoHourFactor : base;
}

/// STOPGAP: build the two service levels from the current [estimate] and [now].
List<MessengerServiceLevel> stopgapServiceLevels({
  required MessengerEstimate? estimate,
  required DateTime now,
}) {
  final hasPrice = (estimate?.totalFare ?? 0) > 0;
  final travelMin = (estimate?.durationMin ?? kStopgapInstantTravelFallbackMin)
      .round()
      .clamp(20, 240);

  return [
    MessengerServiceLevel(
      type: kDeliveryInstant,
      title: 'ส่งทันที',
      pickupEtaMin: kStopgapPickupEtaMin,
      deliverBy: now.add(Duration(minutes: kStopgapPickupEtaMin + travelMin)),
      totalFare: stopgapTotalFor(estimate, kDeliveryInstant),
      hasPrice: hasPrice,
    ),
    MessengerServiceLevel(
      type: kDeliveryTwoHour,
      title: 'ส่งด่วนภายใน 2 ชม.',
      pickupEtaMin: kStopgapPickupEtaMin,
      deliverBy: now.add(const Duration(minutes: kStopgapTwoHourWindowMin)),
      totalFare: stopgapTotalFor(estimate, kDeliveryTwoHour),
      hasPrice: hasPrice,
    ),
  ];
}

/// Format a [DateTime] as HH:mm (24h) without a locale dependency.
String formatHhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
