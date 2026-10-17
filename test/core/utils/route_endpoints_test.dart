import 'package:customer_app/core/utils/route_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  // Around ต.ต้นธง, อ.เมืองลำพูน — where the booking-map route overshot the
  // dropoff pin.
  const pickup = LatLng(18.5480, 98.9990);
  const dropoff = LatLng(18.5780, 99.0050);

  group('distanceMeters', () {
    test('is zero for the same point', () {
      expect(distanceMeters(pickup, pickup), 0);
    });

    test('one thousandth of a degree of latitude is ~111 m', () {
      final d = distanceMeters(
        const LatLng(18.5, 99.0),
        const LatLng(18.501, 99.0),
      );
      expect(d, closeTo(111.2, 0.5));
    });
  });

  group('routeMatchesEndpoints', () {
    test('an empty route never matches', () {
      expect(routeMatchesEndpoints(const [], pickup, dropoff), isFalse);
    });

    test('accepts road-snapped ends within the tolerance', () {
      // ~55 m off each pin, as a route snapped to the nearest road would be.
      const route = [
        LatLng(18.5485, 98.9990),
        LatLng(18.5600, 99.0020),
        LatLng(18.5775, 99.0050),
      ];
      expect(routeMatchesEndpoints(route, pickup, dropoff), isTrue);
    });

    test('rejects a route that ends ~1.5 km past the dropoff', () {
      const route = [
        pickup,
        LatLng(18.5780, 99.0050),
        LatLng(18.5900, 99.0130),
      ];
      expect(routeMatchesEndpoints(route, pickup, dropoff), isFalse);
    });

    test('rejects a route that starts far from the pickup', () {
      const route = [LatLng(18.5300, 98.9900), dropoff];
      expect(routeMatchesEndpoints(route, pickup, dropoff), isFalse);
    });
  });

  group('joinRouteToPins', () {
    test('adds both pins to a road-snapped route', () {
      const route = [LatLng(18.5485, 98.9990), LatLng(18.5775, 99.0050)];
      expect(joinRouteToPins(route, pickup, dropoff), [
        pickup,
        ...route,
        dropoff,
      ]);
    });

    test('does not duplicate pins the route already ends on', () {
      const route = [pickup, LatLng(18.5600, 99.0020), dropoff];
      expect(joinRouteToPins(route, pickup, dropoff), route);
    });

    test('an empty route becomes the straight pickup→dropoff line', () {
      expect(joinRouteToPins(const [], pickup, dropoff), [pickup, dropoff]);
    });
  });
}
