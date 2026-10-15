import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:customer_app/features/messenger/presentation/controllers/messenger_history_controller.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';
import 'package:customer_app/features/trips/presentation/controllers/trips_controller.dart';
import 'package:customer_app/features/trips/presentation/screens/trips_screen.dart';
import 'package:customer_app/features/trips/presentation/states/trips_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(isAuthenticated: true);
}

/// Serves one completed ride and never hits the network.
class _FakeTripsController extends TripsController {
  @override
  TripsState build() => const TripsState(
    historyOrders: [
      HistoryOrder(
        id: 'job-1',
        createdAt: '2026-10-01T10:00:00Z',
        status: 'COMPLETED',
        totalAmount: 120,
        type: 'RIDE',
        rideDetails: HistoryRideDetails(
          id: 'job-1',
          discount: 0,
          fare: 120,
          paymentMethod: 'CASH',
          status: 'COMPLETED',
          pickupAddress: 'Siam',
          dropoffAddress: 'Asok',
        ),
      ),
    ],
  );

  @override
  Future<void> fetchHistoryOrders({
    HistoryType? type,
    HistoryStatus? status,
    bool isRefresh = true,
    int limit = 20,
  }) async {}
}

class _FakeMessengerHistoryController extends MessengerHistoryController {
  @override
  Future<List<MessengerOrder>> build() async => const [];

  @override
  Future<void> refresh() async {}
}

Future<void> _pump(WidgetTester tester, String languageCode) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        tripsControllerProvider.overrideWith(_FakeTripsController.new),
        messengerHistoryControllerProvider.overrideWith(
          _FakeMessengerHistoryController.new,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(languageCode),
        home: const TripsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('English mode renders trip tabs and rows in English', (
    tester,
  ) async {
    await _pump(tester, 'en');

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Rides'), findsOneWidget);
    expect(find.text('Parcels'), findsOneWidget);
    expect(find.text('Siam to Asok'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Book Again'), findsOneWidget);
  });

  testWidgets('Thai mode keeps the Thai trip tabs and rows', (tester) async {
    await _pump(tester, 'th');

    expect(find.text('ทั้งหมด'), findsOneWidget);
    expect(find.text('ส่งอาหาร'), findsOneWidget);
    expect(find.text('เรียกรถ'), findsOneWidget);
    expect(find.text('ส่งของ'), findsOneWidget);
    expect(find.text('Siam ไป Asok'), findsOneWidget);
    expect(find.text('สำเร็จ'), findsOneWidget);
    expect(find.text('จองอีกครั้ง'), findsOneWidget);
  });
}
