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

const _ride = HistoryOrder(
  id: 'job-1',
  createdAt: '2026-10-01T10:00:00Z',
  status: 'COMPLETED',
  totalAmount: 8,
  type: 'RIDE',
  rideDetails: HistoryRideDetails(
    id: 'job-1',
    discount: 30,
    fare: 38,
    paymentMethod: 'CASH',
    status: 'COMPLETED',
    pickupAddress: 'Siam',
    dropoffAddress: 'Asok',
  ),
);

/// Answers like the real feed: empty at first, the ride after a round trip.
class _SlowTripsController extends TripsController {
  @override
  TripsState build() => const TripsState();

  @override
  Future<void> fetchHistoryOrders({
    HistoryType? type,
    HistoryStatus? status,
    bool isRefresh = true,
    int limit = 20,
  }) async {
    state = state.copyWith(isHistoryLoading: true, historyOrders: []);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!ref.mounted) return;
    state = state.copyWith(
      isHistoryLoading: false,
      historyOrders: type == HistoryType.messenger ? [] : [_ride],
    );
  }
}

class _FakeMessengerHistoryController extends MessengerHistoryController {
  @override
  Future<List<MessengerOrder>> build() async => const [];

  @override
  Future<void> refresh() async {}
}

void main() {
  testWidgets('parcel tab → ride tab still shows the rides', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
          tripsControllerProvider.overrideWith(_SlowTripsController.new),
          messengerHistoryControllerProvider.overrideWith(
            _FakeMessengerHistoryController.new,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('th'),
          home: TripsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('ส่งของ'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('เรียกรถ'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('฿8'), findsOneWidget);
    expect(find.text('คุณยังไม่มีประวัติการเดินทาง'), findsNothing);
  });
}
