import 'dart:async';
import 'package:customer_app/features/live_ride/domain/models/driver_profile_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/live_ride/domain/usecases/cancel_ride_usecase_impl.dart';
import 'package:customer_app/features/live_ride/domain/usecases/get_driver_profile_usecase.dart';
import 'package:customer_app/features/live_ride/presentation/states/live_ride_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

part 'live_ride_controller.g.dart';

@riverpod
class LiveRideController extends _$LiveRideController {
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  DateTime? _lastLocationUpdateTime;
  Timer? _syncTimer;
  static const _locationUpdateInterval = Duration(seconds: 2);
  static const _syncInterval = Duration(seconds: 5);

  @override
  LiveRideState build() {
    _initSocket();
    _startSyncPolling();
    ref.onDispose(() {
      _socketSubscription?.cancel();
      _syncTimer?.cancel();
    });
    return const LiveRideState();
  }

  void _initSocket() {
    final socket = ref.read(socketServiceProvider);
    // Connect to websocket if not already
    socket.connect();

    _socketSubscription = socket.messages.listen((message) {
      _handleSocketMessage(message);
    });
  }

  /// Whether a driver has been assigned to the job yet.
  bool get _hasDriver =>
      state.driverId != null && state.driverId!.isNotEmpty;

  /// Fallback for missed/misparsed WebSocket events: while still waiting for a
  /// driver, periodically re-sync from the authoritative source
  /// (`GET /api/customer/jobs/active`) so the customer never stays stuck on the
  /// "finding driver" screen after a driver has actually accepted.
  void _startSyncPolling() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      // No ride in flight yet (e.g. app idle on the home tab) — nothing to
      // re-sync. Skip the tick WITHOUT cancelling so polling resumes once a
      // job is initialised. Without this the controller, which AuthController
      // instantiates at startup, would hammer GET /api/customer/jobs/active
      // every 5s for the whole session and 404 each time.
      final jobId = state.jobId;
      if (jobId == null || jobId.isEmpty) return;

      final status = state.jobStatus?.toUpperCase();
      final isTerminal = status == 'COMPLETED' || status == 'CANCELLED';
      if (_hasDriver || isTerminal) {
        _syncTimer?.cancel();
        return;
      }
      getDriverProfile(silent: true);
    });
  }

  void _handleSocketMessage(Map<String, dynamic> message) {
    final type = (message['type'] as String?)?.toLowerCase();
    final data = message['data'] as Map<String, dynamic>?;

    if (type == null) return;
    debugPrint('LiveRideController: Received message [$type]: $message');

    switch (type) {
      case 'job_accepted':
        getDriverProfile();
        break;
      case 'job_status':
        // Handle top-level keys as per websocket_integration.md
        final status = ((data?['status'] ?? message['status']) as String?)
            ?.toUpperCase();
        if (status != null) {
          state = state.copyWith(jobStatus: status);
          // A driver was (or is being) assigned but we don't have their details
          // yet — pull the authoritative job so the confirming screen populates.
          if (!_hasDriver && status != 'PENDING' && status != 'CANCELLED') {
            getDriverProfile(silent: true);
          }
        }
        break;
      case 'driver_location':
        final lat = data?['lat'] as num?;
        final lng = data?['lng'] as num?;
        if (lat != null && lng != null) {
          final now = DateTime.now();
          if (_lastLocationUpdateTime == null ||
              now.difference(_lastLocationUpdateTime!) >=
                  _locationUpdateInterval) {
            _lastLocationUpdateTime = now;
            state = state.copyWith(
              driverLocation: LatLng(lat.toDouble(), lng.toDouble()),
            );
          }
        }
        break;
      case 'error':
        state = state.copyWith(error: data.toString());
        break;
      default:
        debugPrint('Unhandled socket message type: $type');
    }
  }

  Future<void> getDriverProfile({bool silent = false}) async {
    try {
      if (!silent) {
        state = state.copyWith(isLoading: true, error: null);
      }
      // Invalidate the usecase to ensure we fetch fresh data if needed,
      // or just read the future if it's already fetching.
      final liveState = await ref.refresh(
        getDriverProfileUsecaseProvider.future,
      );
      state = state.copyWith(
        isLoading: false,
        jobId: liveState.id,
        driverId: liveState.driverId,
        driverName: liveState.driverJobInfo?.fullName,
        vehiclePlate: liveState.driverJobInfo?.vehiclePlate,
        vehicleColor: liveState.driverJobInfo?.vehicleColor,
        vehicleType: liveState.driverJobInfo?.vehicleModel,
        driverRating: liveState.driverJobInfo?.rating,
        jobStatus: liveState.status,
        fare: liveState.fare,
        discount: liveState.discount,
        driverProfile: DriverProfileModel.fromActiveJob(liveState),
      );

      // Restore locations in HomeController
      ref
          .read(homeControllerProvider.notifier)
          .setPickupLocation(
            LatLng(liveState.pickupLat, liveState.pickupLng),
            liveState.pickupAddress,
          );
      ref
          .read(homeControllerProvider.notifier)
          .setDropoffLocation(
            LatLng(liveState.dropoffLat, liveState.dropoffLng),
            liveState.dropoffAddress,
          );

      // Restore polyline and details in BookingController
      ref
          .read(bookingControllerProvider.notifier)
          .restoreFromActiveJob(
            distanceKm: liveState.distanceKm,
            durationMin: null, // Travel duration is not directly in the model
            polyline: liveState.polyline,
          );
    } catch (e) {
      // No active job yet (still searching for a driver) is expected while
      // polling — don't treat it as an error or log noise.
      final noActiveJob = e.toString().contains('NO_ACTIVE_JOB');
      if (noActiveJob) return;

      // Background sync polls must not surface transient errors to the UI.
      if (!silent) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        debugPrint('LiveRideController: silent sync failed: $e');
      }
    }
  }

  Future<bool> cancelRide() async {
    if (state.jobId == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(cancelRideUseCaseProvider).call(state.jobId!);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false, jobStatus: 'CANCELLED');
        return true;
      },
    );
  }

  // Pre-load a job (e.g. from app restart)
  void initializeWithJob(Map<String, dynamic> jobData) {
    state = state.copyWith(
      jobId: jobData['id'],
      jobStatus: jobData['status'] ?? 'PENDING',
      driverId: jobData['driver_id'],
      fare: (jobData['fare'] as num?)?.toDouble(),
      discount: (jobData['discount'] as num?)?.toDouble(),
    );

    // If status is not provided (e.g., app restart), or if it is an active state,
    // fetch the latest details from the server to restore state correctly.
    if (jobData['status'] == null ||
        jobData['status'] == 'PENDING' ||
        jobData['status'] == 'ACCEPTED' ||
        jobData['status'] == 'ARRIVED_AT_PICK_UP' ||
        jobData['status'] == 'PICKED_UP') {
      getDriverProfile();
    }
  }
}
