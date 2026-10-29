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

  @override
  Stream<Map<String, dynamic>> get messages => const Stream.empty();

  @override
  void connect({bool isReconnect = false}) {}

  @override
  void disconnect() {}
}

/// `GET /api/customer/jobs/:id` answers from [statuses]; the active ride
/// (`/jobs/active`) is [active], or none (404).
class _Repo implements IDriverProfileRepository {
  final statuses = <String, String?>{};
  CustomerJobsActiveModel? active;
  bool statusFails = false;
  final asked = <String>[];

  @override
  Future<CustomerJobsActiveModel> getDriverProfile() async {
    final a = active;
    if (a == null) throw Exception('NO_ACTIVE_JOB');
    return a;
  }

  @override
  Future<String?> getJobStatus(String jobId) async {
    asked.add(jobId);
    if (statusFails) throw Exception('offline');
    return statuses[jobId];
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Repo repo;
  late ProviderContainer c;

  LiveRideController controller() =>
      c.read(liveRideControllerProvider.notifier);
  LiveRideState state() => c.read(liveRideControllerProvider);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = _Repo();
    c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        socketServiceProvider.overrideWithValue(_Socket(TokenStorage(prefs))),
        driverProfileRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    c.listen(liveRideControllerProvider, (_, _) {});
  });

  test('an old ride from a notification is never shown as live', () async {
    repo.statuses['old'] = 'COMPLETED';
    expect(await controller().openJob('old'), LiveJobOpening.ended);
    expect(state().jobId, isNull, reason: 'nothing of it is kept');
  });

  test('a ride that is not the customer\'s goes nowhere', () async {
    expect(await controller().openJob('nope'), LiveJobOpening.missing);
  });

  test('an old ride leaves the ride under way alone', () async {
    repo.statuses
      ..['now'] = 'PICKED_UP'
      ..['old'] = 'CANCELLED';
    await controller().openJob('now');
    await _settle();
    expect(await controller().openJob('old'), LiveJobOpening.ended);
    expect(state().jobId, 'now');
    expect(state().jobStatus, 'PICKED_UP');
  });

  test('the ride being followed just ended: the screen sees it end', () async {
    repo.statuses['r1'] = 'ACCEPTED';
    await controller().openJob('r1');
    await _settle();
    repo.statuses['r1'] = 'CANCELLED';
    expect(await controller().openJob('r1'), LiveJobOpening.ending);
    expect(state().jobStatus, 'CANCELLED');
  });

  test('a new ride starts clean: no driver of the last one', () async {
    repo.statuses['r1'] = 'ACCEPTED';
    await controller().openJob('r1');
    await _settle();
    c.read(liveRideControllerProvider.notifier).state = state().copyWith(
      driverId: 'd1',
      driverName: 'สมชาย',
      jobStatus: 'COMPLETED',
    );
    repo.statuses['r2'] = 'PENDING';
    expect(await controller().openJob('r2'), LiveJobOpening.live);
    expect(state().jobId, 'r2');
    expect(state().jobStatus, 'PENDING');
    expect(state().driverId, isNull);
    expect(state().driverName, isNull);
  });

  test('status unreadable (offline): tracked as before', () async {
    repo.statusFails = true;
    expect(await controller().openJob('r1'), LiveJobOpening.live);
    expect(state().jobId, 'r1');
  });

  test(
    'cancelled while the app was away: off the active list → ends',
    () async {
      repo.statuses['r1'] = 'ACCEPTED';
      await controller().openJob('r1');
      await _settle();
      expect(state().jobStatus, 'ACCEPTED');

      repo.statuses['r1'] = 'CANCELLED';
      await controller().getDriverProfile(silent: true);
      expect(state().jobStatus, 'CANCELLED');
    },
  );

  test('still searching (not on the active list yet) stays', () async {
    repo.statuses['r1'] = 'PENDING';
    await controller().openJob('r1');
    await controller().getDriverProfile(silent: true);
    expect(state().jobStatus, 'PENDING');
  });

  test('another ride is the active one: ours is over, not replaced', () async {
    repo.statuses['old'] = 'ACCEPTED';
    await controller().openJob('old');
    await _settle();
    repo.statuses['old'] = 'COMPLETED';
    repo.active = const CustomerJobsActiveModel(id: 'new', status: 'ACCEPTED');
    await controller().getDriverProfile(silent: true);
    expect(state().jobId, 'old');
    expect(state().jobStatus, 'COMPLETED');
  });

  test('isRideActiveStatus', () {
    for (final s in [
      'PENDING',
      'accepted',
      'ARRIVED_AT_PICK_UP',
      'PICKED_UP',
    ]) {
      expect(isRideActiveStatus(s), isTrue, reason: s);
    }
    for (final s in ['COMPLETED', 'CANCELLED', null]) {
      expect(isRideActiveStatus(s), isFalse, reason: '$s');
    }
  });
}
