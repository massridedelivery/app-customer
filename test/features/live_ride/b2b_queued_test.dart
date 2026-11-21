import 'dart:async';

import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/live_ride/data/repositories/driver_profile_repository_impl.dart';
import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';
import 'package:customer_app/features/live_ride/domain/models/queued_next.dart';
import 'package:customer_app/features/live_ride/domain/repositories/i_driver_profile_repository.dart';
import 'package:customer_app/features/live_ride/presentation/controllers/live_ride_controller.dart';
import 'package:customer_app/features/live_ride/presentation/states/live_ride_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Socket extends SocketService {
  _Socket(super.tokenStorage);

  final frames = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messages => frames.stream;

  @override
  void connect({bool isReconnect = false}) {}

  @override
  void disconnect() {}
}

class _Repo implements IDriverProfileRepository {
  CustomerJobsActiveModel? active;

  @override
  Future<CustomerJobsActiveModel> getDriverProfile() async {
    final a = active;
    if (a == null) throw Exception('NO_ACTIVE_JOB');
    return a;
  }

  @override
  Future<String?> getJobStatus(String jobId) async => active?.status;
}

// backend job.QueuedNext.
const _queued = {
  'driver_id': 'd7',
  'driver_info': {
    'full_name': 'สมชาย',
    'avatar_url': 'https://cdn.test/a.jpg',
    'rating': 4.9,
    'vehicle_plate': '1กข 1234',
    'vehicle_province': 'กรุงเทพมหานคร',
    'vehicle_model': 'Vios',
    'vehicle_color': 'ขาว',
  },
  'eta_min': 7,
  'arrive_by': '2026-11-21T10:20:00Z',
};

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QueuedNext.fromJson', () {
    test('reads the driver and the ETA', () {
      final q = QueuedNext.fromJson(_queued)!;
      expect(q.driverId, 'd7');
      expect(q.driverName, 'สมชาย');
      expect(q.vehiclePlate, '1กข 1234');
      expect(q.rating, 4.9);
      expect(q.etaMin, 7);
      expect(q.arriveBy, DateTime.utc(2026, 11, 21, 10, 20));
    });

    test('no driver_id or not a map → null', () {
      expect(QueuedNext.fromJson(null), isNull);
      expect(QueuedNext.fromJson('x'), isNull);
      expect(QueuedNext.fromJson({'eta_min': 3}), isNull);
      expect(QueuedNext.fromJson({'driver_id': 'd1'})!.etaMin, isNull);
    });
  });

  group('LiveRideController back-to-back', () {
    late _Repo repo;
    late _Socket socket;
    late ProviderContainer c;

    LiveRideState state() => c.read(liveRideControllerProvider);

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
      repo.active = const CustomerJobsActiveModel(id: 'r1', status: 'PENDING');
      await c.read(liveRideControllerProvider.notifier).openJob('r1');
    });

    test(
      'job_queued shows the queued driver; job_unqueued clears it',
      () async {
        socket.frames.add({
          'type': 'job_queued',
          'job_id': 'r1',
          'queued_next': _queued,
        });
        await _settle();
        expect(state().queuedNext?.driverName, 'สมชาย');
        expect(state().queuedNext?.etaMin, 7);
        // Still searching: no driver on the ride itself.
        expect(state().driverId ?? '', isEmpty);

        socket.frames.add({
          'type': 'job_unqueued',
          'job_id': 'r1',
          'reason': 'timeout',
        });
        await _settle();
        expect(state().queuedNext, isNull);
      },
    );

    test('a frame for another ride is ignored', () async {
      socket.frames.add({
        'type': 'job_queued',
        'job_id': 'other',
        'queued_next': _queued,
      });
      await _settle();
      expect(state().queuedNext, isNull);
    });

    test('after a reload, queued_next on /jobs/active restores it', () async {
      repo.active = const CustomerJobsActiveModel(
        id: 'r1',
        status: 'PENDING',
        queuedNext: _queued,
      );
      await c
          .read(liveRideControllerProvider.notifier)
          .getDriverProfile(silent: true);
      expect(state().queuedNext?.driverId, 'd7');

      // Accepted: the ride has its driver, the queue card goes.
      repo.active = const CustomerJobsActiveModel(
        id: 'r1',
        status: 'ACCEPTED',
        driverId: 'd7',
        queuedNext: _queued,
      );
      await c
          .read(liveRideControllerProvider.notifier)
          .getDriverProfile(silent: true);
      expect(state().queuedNext, isNull);
    });
  });
}
