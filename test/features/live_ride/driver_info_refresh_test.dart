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

  @override
  Stream<Map<String, dynamic>> get messages => frames.stream;

  @override
  void connect({bool isReconnect = false}) {}

  @override
  void disconnect() {}
}

class _Repo implements IDriverProfileRepository {
  CustomerJobsActiveModel? active;
  var reads = 0;

  @override
  Future<CustomerJobsActiveModel> getDriverProfile() async {
    reads++;
    final a = active;
    if (a == null) throw Exception('NO_ACTIVE_JOB');
    return a;
  }

  @override
  Future<String?> getJobStatus(String jobId) async => active?.status;
}

CustomerJobsActiveModel _job(String status, String avatar) =>
    CustomerJobsActiveModel(
      id: 'r1',
      status: status,
      driverId: 'd1',
      driverJobInfo: DriverJobInfoModel(
        fullName: 'สมชาย',
        avatarUrl: avatar,
        vehiclePlate: '1กข 1234',
      ),
    );

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
  });

  test('job_accepted shows the driver, photo included, at once', () async {
    repo.active = _job('ACCEPTED', 'https://cdn.test/avatar/d1/a.jpg');
    await c.read(liveRideControllerProvider.notifier).openJob('r1');
    socket.frames.add({
      'type': 'job_accepted',
      'job': {'id': 'r1'},
    });
    await _settle();
    expect(state().driverName, 'สมชาย');
    expect(
      state().driverProfile?.driverInfo.avatarUrl,
      'https://cdn.test/avatar/d1/a.jpg',
    );
  });

  test('job_status with a driver already known re-reads the job', () async {
    repo.active = _job('ACCEPTED', 'https://cdn.test/avatar/d1/a.jpg');
    await c.read(liveRideControllerProvider.notifier).openJob('r1');
    await c
        .read(liveRideControllerProvider.notifier)
        .getDriverProfile(silent: true);
    expect(state().driverId, 'd1');

    repo.active = _job(
      'ARRIVED_AT_PICK_UP',
      'https://cdn.test/avatar/d1/b.jpg',
    );
    final before = repo.reads;
    socket.frames.add({'type': 'job_status', 'status': 'ARRIVED_AT_PICK_UP'});
    await _settle();
    expect(repo.reads, before + 1);
    expect(state().jobStatus, 'ARRIVED_AT_PICK_UP');
    expect(
      state().driverProfile?.driverInfo.avatarUrl,
      'https://cdn.test/avatar/d1/b.jpg',
    );
  });

  test('an ended ride is not re-read on job_status', () async {
    repo.active = _job('PICKED_UP', '');
    await c.read(liveRideControllerProvider.notifier).openJob('r1');
    await _settle();
    final before = repo.reads;
    socket.frames.add({'type': 'job_status', 'status': 'COMPLETED'});
    await _settle();
    expect(repo.reads, before);
    expect(state().jobStatus, 'COMPLETED');
  });
}
