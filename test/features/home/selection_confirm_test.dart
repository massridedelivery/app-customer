import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/home/presentation/widgets/ride_selection_view.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Returns a fixed HomeState and skips the real build() (geolocation, network,
/// saved/recent loaders). Every method under test is the real implementation.
class _FakeHomeController extends HomeController {
  _FakeHomeController(this._initial);
  final HomeState _initial;

  @override
  HomeState build() => _initial;
}

const _oldPickup = LatLng(13.70, 100.50);
const _newPin = LatLng(13.80, 100.60);

ProviderContainer _container(HomeState state) {
  final container = ProviderContainer(
    overrides: [
      homeControllerProvider.overrideWith(() => _FakeHomeController(state)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Widget _wrap(HomeState state) {
  return ProviderScope(
    overrides: [
      homeControllerProvider.overrideWith(() => _FakeHomeController(state)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('th'),
      home: Scaffold(body: RideSelectionView()),
    ),
  );
}

ElevatedButton _confirmButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'ถัดไป'),
    );

void main() {
  group('confirmSelection', () {
    test('refuses while the address lookup is still out', () {
      // onCameraIdle publishes the coordinate first and the address only once
      // the reverse geocode returns — this is that in-between moment.
      final container = _container(
        const HomeState(
          selectionMode: RideSelectionMode.pickup,
          pickupLocation: _oldPickup,
          pickupAddress: 'Old pickup',
          tempLocation: _newPin,
        ),
      );
      final notifier = container.read(homeControllerProvider.notifier);

      expect(notifier.confirmSelection(), isFalse);

      final state = container.read(homeControllerProvider);
      expect(
        state.pickupLocation,
        _oldPickup,
        reason: 'a refused confirm must leave the existing pickup untouched',
      );
      expect(state.pickupAddress, 'Old pickup');
      expect(state.selectionMode, RideSelectionMode.pickup);
    });

    test('refuses before the camera has settled at all', () {
      final container = _container(
        const HomeState(
          selectionMode: RideSelectionMode.dropoff,
          dropoffLocation: _oldPickup,
          dropoffAddress: 'Old dropoff',
        ),
      );
      final notifier = container.read(homeControllerProvider.notifier);

      expect(notifier.confirmSelection(), isFalse);
      expect(container.read(homeControllerProvider).dropoffLocation, _oldPickup);
    });

    test('commits once both the coordinate and the address are in', () {
      final container = _container(
        const HomeState(
          selectionMode: RideSelectionMode.dropoff,
          tempLocation: _newPin,
          tempAddress: 'New place',
        ),
      );
      final notifier = container.read(homeControllerProvider.notifier);

      expect(notifier.confirmSelection(), isTrue);

      final state = container.read(homeControllerProvider);
      expect(state.dropoffLocation, _newPin);
      expect(state.dropoffAddress, 'New place');
      expect(state.selectionMode, RideSelectionMode.none);
      expect(state.tempLocation, isNull);
      expect(state.tempAddress, isNull);
    });
  });

  group('RideSelectionView', () {
    testWidgets('disables the action until the selection resolves', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const HomeState(
            selectionMode: RideSelectionMode.pickup,
            pickupAddress: 'Old pickup',
            tempLocation: _newPin,
          ),
        ),
      );

      expect(_confirmButton(tester).onPressed, isNull);
      expect(
        find.text('Old pickup'),
        findsNothing,
        reason: 'the previous address must not read as this pin\'s address',
      );
    });

    testWidgets('enables the action once the address lands', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HomeState(
            selectionMode: RideSelectionMode.pickup,
            tempLocation: _newPin,
            tempAddress: 'New place',
          ),
        ),
      );

      expect(_confirmButton(tester).onPressed, isNotNull);
      expect(find.text('New place'), findsOneWidget);
    });
  });
}
