import 'dart:async';

import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/live_ride/data/repositories/driver_profile_repository_impl.dart';
import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';
import 'package:customer_app/features/live_ride/domain/repositories/i_driver_profile_repository.dart';
import 'package:customer_app/features/live_ride/presentation/controllers/live_ride_controller.dart';
import 'package:customer_app/features/live_ride/presentation/states/live_ride_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Socket extends SocketService {
  _Socket(super.tokenStorage);

  final frames = StreamController<Map<String, dynamic>>.broadcast();
  final back = StreamController<void>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messages => frames.stream;

  @override
  Stream<void> get reconnected => back.stream;

  @override
  void connect({bool isReconnect = false}) {}

  @override
  void disconnect() {}
}

class _Repo implements IDriverProfileRepository {
  CustomerJobsActiveModel active = const CustomerJobsActiveModel(
    id: 'r1',
    status: 'ACCEPTED',
    driverId: 'd1',
  );
  var reads = 0;

  @override
  Future<CustomerJobsActiveModel> getDriverProfile() async {
    reads++;
    return active;
  }

  @override
  Future<String?> getJobStatus(String jobId) async => active.status;
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Repo repo;
  late _Socket socket;
  late ProviderContainer c;

  LiveRideState state() => c.read(liveRideControllerProvider);

  void location(Map<String, dynamic> extra) => socket.frames.add({
    'type': 'driver_location',
    'data': {'lat': 13.75, 'lng': 100.5, ...extra},
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = _Repo();
    socket = _Socket(TokenStorage(prefs));
    c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        socketServiceProvider.overrideWithValue(socket),
        driverProfileRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    c.listen(liveRideControllerProvider, (_, _) {});
    await c.read(liveRideControllerProvider.notifier).openJob('r1');
    await _settle();
  });

  test('the ETA comes from data.arrive_at and goes when the keys do', () async {
    location({'eta_min': 6, 'arrive_at': '2026-11-05T09:30:00Z'});
    await _settle();
    expect(state().etaArriveAt, DateTime.utc(2026, 11, 5, 9, 30).toLocal());

    // Keys absent (not 0): drop the last figure.
    location({});
    await _settle();
    expect(state().etaArriveAt, isNull);
  });

  test('an ETA change counts even inside the map throttle', () async {
    location({'arrive_at': '2026-11-05T09:30:00Z'});
    location({'arrive_at': '2026-11-05T09:34:00Z'});
    await _settle();
    expect(state().etaArriveAt, DateTime.utc(2026, 11, 5, 9, 34).toLocal());
  });

  test('a resync without ETA keys clears the old figure', () async {
    location({'arrive_at': '2026-11-05T09:30:00Z'});
    await _settle();
    expect(state().etaArriveAt, isNotNull);
    await c
        .read(liveRideControllerProvider.notifier)
        .getDriverProfile(silent: true);
    expect(state().etaArriveAt, isNull);

    repo.active = repo.active.copyWith(arriveAt: '2026-11-05T09:40:00Z');
    await c
        .read(liveRideControllerProvider.notifier)
        .getDriverProfile(silent: true);
    expect(state().etaArriveAt, DateTime.utc(2026, 11, 5, 9, 40).toLocal());
  });

  test('a socket reconnect resyncs the active job', () async {
    final before = repo.reads;
    socket.back.add(null);
    await _settle();
    expect(repo.reads, before + 1);
  });
}
