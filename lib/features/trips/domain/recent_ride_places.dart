import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';

/// Most-recent ride destinations pulled from order history, de-duplicated by
/// address, as tappable [Place]s (name = address, plus its coordinates).
///
/// Shared by the ride landing screen and the place-search "recent" tab so both
/// draw from the same reliable source — the customer's real trip history —
/// instead of the flaky `/places/frequent` list, which returned intermittently
/// and left "recent" appearing/disappearing between visits.
List<Place> recentRidePlaces(List<HistoryOrder> orders, {int limit = 3}) {
  final seen = <String>{};
  final places = <Place>[];
  for (final order in orders) {
    if (order.type.toUpperCase() != 'RIDE') continue;
    final ride = order.rideDetails;
    if (ride == null || ride.dropoffLat == null || ride.dropoffLng == null) {
      continue;
    }
    final address = (ride.dropoffAddress ?? '').trim();
    if (address.isEmpty || !seen.add(address)) continue;
    places.add(
      Place(name: address, lat: ride.dropoffLat!, lng: ride.dropoffLng!),
    );
    if (places.length >= limit) break;
  }
  return places;
}
