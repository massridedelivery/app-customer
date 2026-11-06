import 'package:customer_app/features/home/presentation/screens/service_selection_screen.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  const gps = LatLng(12.53, 99.96);
  const pickup = LatLng(12.57, 99.95);
  const food = LatLng(12.60, 99.94);

  test('GPS first', () {
    expect(
      zoneCheckLocation(
        const HomeState(
          currentLocation: gps,
          pickupLocation: pickup,
          foodLocation: food,
        ),
      ),
      gps,
    );
  });

  test('GPS still resolving: the pickup, then the food address', () {
    expect(
      zoneCheckLocation(
        const HomeState(pickupLocation: pickup, foodLocation: food),
      ),
      pickup,
    );
    expect(zoneCheckLocation(const HomeState(foodLocation: food)), food);
  });

  test('nothing known: no check', () {
    expect(zoneCheckLocation(const HomeState()), isNull);
  });
}
