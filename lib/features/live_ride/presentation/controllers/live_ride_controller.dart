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
import 'package:flutter/widgets.dart';

part 'live_ride_controller.g.dart';

@riverpod
class LiveRideController extends _$LiveRideController {
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  DateTime? _lastLocationUpdateTime;
  Timer? _syncTimer;
  AppLifecycleListener? _lifecycleListener;
  int _syncTick = 0;
  static const _locationUpdateInterval = Duration(seconds: 2);
  static const _syncInterval = Duration(seconds: 5);

  @override
  LiveRideState build() {
    _initSocket();
    _startSyncPolling();
    // Re-sync the instant the app returns to the foreground — see [_onResume].
    _lifecycleListener = AppLifecycleListener(onResume: _onResume);
    ref.onDispose(() {
      _socketSubscription?.cancel();
      _syncTimer?.cancel();
      _lifecycleListener?.dispose();
    });
    return const LiveRideState();
  }

  /// The app just came back to the foreground. The socket reconnects centrally
  /// (App.didChangeAppLifecycleState → SocketService.ensureConnected), but any
  /// WebSocket frame the server pushed while we were backgrounded is gone — the
  /// socket was suspended and there is no replay on reconnect. So pull the
  /// authoritative job straight away instead of waiting up to ~10s for the next
  /// [_startSyncPolling] tick. This is what makes a ride the driver finished
  /// while the user was in another app resolve immediately on return, rather
  /// than leaving the screen stuck on "on trip" / "finding driver".
  void _onResume() {
    final jobId = state.jobId;
    if (jobId == null || jobId.isEmpty) return;
    final status = state.jobStatus?.toUpperCase();
    if (status == 'COMPLETED' || status == 'CANCELLED') return;
    getDriverProfile(silent: true);
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

  /// Fallback for missed/misparsed WebSocket events: periodically re-sync from
  /// the authoritative source (`GET /api/customer/jobs/active`) so the customer
  /// never stays stuck on the live-ride screen when a WS frame is lost.
  ///
  /// Runs until the job reaches a terminal status. Before a driver is assigned
  /// it polls every tick (5s) so the "finding driver" screen advances quickly;
  /// after assignment it keeps polling but at ~10s. The slower on-trip poll is
  /// what recovers a `COMPLETED` that was pushed while the socket was suspended
  /// (app backgrounded → the frame is lost, and there is no WS replay on
  /// reconnect). Previously the poll stopped the moment a driver was assigned,
  /// so after that the screen depended solely on the WS and could stay stuck on
  /// "on trip" after the driver had already finished.
  void _startSyncPolling() {
    _syncTimer?.cancel();
    _syncTick = 0;
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
      if (isTerminal) {
        _syncTimer?.cancel();
        return;
      }

      // Throttle to ~10s once a driver is assigned; keep 5s while searching.
      _syncTick++;
      if (!_hasDriver || _syncTick.isEven) {
        getDriverProfile(silent: true);
      }
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
        // Server-computed arrival time to the current target — pushed alongside
        // the location so the client never calls a routing API. Prefer an
        // absolute `arrive_at` (stable clock); fall back to `eta_min` (now + N).
        // Optional: absent until the backend ships it (last value kept).
        final arriveAt = _parseEta(data);
        if (lat != null && lng != null) {
          final now = DateTime.now();
          if (_lastLocationUpdateTime == null ||
              now.difference(_lastLocationUpdateTime!) >=
                  _locationUpdateInterval) {
            _lastLocationUpdateTime = now;
            state = state.copyWith(
              driverLocation: LatLng(lat.toDouble(), lng.toDouble()),
              etaArriveAt: arriveAt ?? state.etaArriveAt,
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
        estimatedCancelFee: liveState.estimatedCancelFee,
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
      if (noActiveJob) {
        // The job dropped off the active list. If we were already on the trip
        // (picked up, driver assigned), it finished while we weren't receiving
        // live updates — the socket was suspended in the background and the
        // COMPLETED frame was missed (no WS replay on reconnect). Mark it
        // completed so the summary flow runs instead of the screen staying
        // stuck on "on trip". Gated to PICKED_UP so a still-searching poll
        // (no active job yet) is never misread as a completed ride.
        if (_hasDriver && state.jobStatus?.toUpperCase() == 'PICKED_UP') {
          state = state.copyWith(jobStatus: 'COMPLETED');
        }
        return;
      }

      // Background sync polls must not surface transient errors to the UI.
      if (!silent) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        debugPrint('LiveRideController: silent sync failed: $e');
      }
    }
  }

  /// Arrival time from a driver-location payload: prefers an absolute
  /// `arrive_at` (ISO8601); otherwise derives it from `eta_min` (now + N min).
  /// Null when neither is present.
  DateTime? _parseEta(Map<String, dynamic>? data) {
    if (data == null) return null;
    final iso = data['arrive_at'] as String?;
    if (iso != null && iso.isNotEmpty) {
      return DateTime.tryParse(iso)?.toLocal();
    }
    final etaMin =
        (data['eta_min'] ?? data['eta_minutes'] ?? data['eta']) as num?;
    if (etaMin != null) {
      return DateTime.now().add(Duration(minutes: etaMin.round()));
    }
    return null;
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
      (fee) {
        state = state.copyWith(
          isLoading: false,
          jobStatus: 'CANCELLED',
          chargedCancelFee: fee,
        );
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
