import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/screens/transport/ride_landing_screen.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Returns a fixed HomeState and skips the real build() (geolocation, network,
/// saved/recent loaders) so the screen renders deterministically.
class _FakeHomeController extends HomeController {
  _FakeHomeController(this._initial);
  final HomeState _initial;

  @override
  HomeState build() => _initial;
}

Place _place(String name, String address) =>
    Place(name: name, lat: 13.7, lng: 100.5, address: address);

Widget _wrap(HomeState state) {
  return ProviderScope(
    overrides: [
      homeControllerProvider.overrideWith(() => _FakeHomeController(state)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('th'),
      home: RideLandingScreen(),
    ),
  );
}

void main() {
  testWidgets('renders recent places from state, collapsed to 3', (
    tester,
  ) async {
    final places = List.generate(
      5,
      (i) => _place('Place $i', 'Recent address $i'),
    );
    await tester.pumpWidget(_wrap(HomeState(recentPlaces: places)));
    await tester.pump();

    expect(find.text('การเดินทางล่าสุด'), findsOneWidget);
    expect(find.text('Recent address 0'), findsOneWidget);
    expect(find.text('Recent address 2'), findsOneWidget);
    // Only the first 3 are shown; the rest are not rendered (no "see more").
    expect(find.text('Recent address 3'), findsNothing);
    expect(find.text('Recent address 4'), findsNothing);
  });

  testWidgets('caps the recent list at 3 with no "see more" affordance', (
    tester,
  ) async {
    final places = List.generate(
      5,
      (i) => _place('Place $i', 'Recent address $i'),
    );
    await tester.pumpWidget(_wrap(HomeState(recentPlaces: places)));
    await tester.pump();

    // The section shows the first 3 only and offers no way to reveal more.
    expect(find.text('ดูเพิ่มเติม'), findsNothing);
    expect(find.text('Recent address 3'), findsNothing);
    expect(find.text('Recent address 4'), findsNothing);
  });

  testWidgets('no "see more" button when 3 or fewer', (tester) async {
    final places = List.generate(
      3,
      (i) => _place('Place $i', 'Recent address $i'),
    );
    await tester.pumpWidget(_wrap(HomeState(recentPlaces: places)));
    await tester.pump();

    expect(find.text('ดูเพิ่มเติม'), findsNothing);
  });

  testWidgets('hides the recent section entirely when empty', (tester) async {
    await tester.pumpWidget(_wrap(const HomeState(recentPlaces: [])));
    await tester.pump();

    expect(find.text('การเดินทางล่าสุด'), findsNothing);
  });

  testWidgets('"เพิ่มที่อยู่" navigates to the /add-address route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (c, s) => const RideLandingScreen()),
        GoRoute(
          path: '/add-address',
          builder: (c, s) =>
              const Scaffold(body: Center(child: Text('ADD_ADDRESS_ROUTE'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeControllerProvider.overrideWith(
            () => _FakeHomeController(const HomeState()),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('th'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('เพิ่มที่อยู่'));
    await tester.pumpAndSettle();

    expect(find.text('ADD_ADDRESS_ROUTE'), findsOneWidget);
  });
}
