import 'dart:async';
import 'dart:convert';
import 'package:customer_app/features/live_ride/domain/models/driver_profile_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/live_ride/data/repositories/driver_profile_repository_impl.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/live_ride/domain/usecases/cancel_ride_usecase_impl.dart';
import 'package:customer_app/features/live_ride/presentation/states/live_ride_state.dart';
import 'package:customer_app/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/widgets.dart';

part 'live_ride_controller.g.dart';

/// What [LiveRideController.openJob] found.
enum LiveJobOpening {
  /// Under way (or unreadable): the screen tracks it.
  live,

  /// The ride this session was following just ended: the live screen's own
  /// listener takes it to the summary (completed) or home (cancelled).
  ending,

  /// Over for a while — an old notification, say. Never shown as live.
  ended,

  /// Not one of this customer's rides.
  missing,
}

/// A ride still under way.
bool isRideActiveStatus(String? status) => const {
  'PENDING',
  'ACCEPTED',
  'ARRIVED_AT_PICK_UP',
  'PICKED_UP',
}.contains(status?.toUpperCase());

@riverpod
class LiveRideController extends _$LiveRideController {
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  StreamSubscription<void>? _reconnectSubscription;
  DateTime? _lastLocationUpdateTime;
  AppLifecycleListener? _lifecycleListener;
  static const _locationUpdateInterval = Duration(seconds: 2);

  @override
  LiveRideState build() {
    _initSocket();
    // Re-sync the instant the app returns to the foreground — see [_onResume].
    _lifecycleListener = AppLifecycleListener(onResume: _onResume);
    ref.onDispose(() {
      _socketSubscription?.cancel();
      _reconnectSubscription?.cancel();
      _lifecycleListener?.dispose();
    });
    return const LiveRideState();
  }

  /// The app just came back to the foreground. The socket reconnects centrally
  /// (App.didChangeAppLifecycleState → SocketService.ensureConnected), but any
  /// WebSocket frame the server pushed while we were backgrounded is gone — the
  /// socket was suspended and there is no replay on reconnect. So pull the
  /// authoritative job straight away (`GET /api/customer/jobs/active`, which is
  /// never polled: it resyncs on open, resume and socket reconnect only). This
  /// is what makes a ride the driver finished
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

    // A socket that dropped and came back mid-ride missed every frame in the
    // gap (no server replay). Pull the authoritative job immediately on
    // reconnect so a status change that happened during the outage shows at
    // once.
    _reconnectSubscription = socket.reconnected.listen((_) {
      final jobId = state.jobId;
      if (jobId == null || jobId.isEmpty) return;
      final status = state.jobStatus?.toUpperCase();
      if (status == 'COMPLETED' || status == 'CANCELLED') return;
      getDriverProfile(silent: true);
    });
  }

  /// Whether a driver has been assigned to the job yet.
  bool get _hasDriver =>
      state.driverId != null && state.driverId!.isNotEmpty;

  /// Socket `data` is usually an object, but some events send it as a JSON
  /// string or a plain string (iOS 1.0.3: "String is not a subtype of Map").
  static Map<String, dynamic>? _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trimLeft().startsWith('{')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  void _handleSocketMessage(Map<String, dynamic> message) {
    final type = (message['type'] as String?)?.toLowerCase();
    final data = _asMap(message['data']);

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
        // System-initiated cancels carry a reason (SCRUM-111), e.g.
        // "driver_unavailable"; a user-initiated cancel has none.
        final reason = (data?['reason'] ?? message['reason']) as String?;
        if (status != null) {
          state = state.copyWith(
            jobStatus: status,
            cancelReason: status == 'CANCELLED' ? reason : null,
          );
          // Pull the authoritative job on every live status so the driver's
          // details (name, photo, vehicle) follow the status without waiting
          // for the next poll. Ended rides resolve through their own path.
          if (status != 'PENDING' &&
              status != 'CANCELLED' &&
              status != 'COMPLETED') {
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
        // ETA keys are sent on every frame while there IS an ETA and vanish
        // entirely when there's none (no active job / routing down). So set
        // it to the parsed value directly — null (absent) drops the last
        // figure ("กำลังเดินทาง") rather than leaving a stale countdown
        // (SCRUM-76). Never default 0. Every frame counts for the ETA, even
        // one the map throttle below skips.
        if (arriveAt != state.etaArriveAt) {
          state = state.copyWith(etaArriveAt: arriveAt);
        }
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
      // Straight from the repository: nothing listens to the usecase
      // provider, which leaves its request at the mercy of auto-dispose.
      final liveState = await ref
          .read(driverProfileRepositoryProvider)
          .getDriverProfile();
      if (!ref.mounted) return;
      // Seed the live ETA from the active job so resync (app resume / restart)
      // shows an ETA immediately, without waiting for the next socket frame
      // (SCRUM-76). Keys absent → no ETA ("กำลังเดินทาง"), like a frame
      // without them.
      final resyncEta =
          (liveState.arriveAt != null && liveState.arriveAt!.isNotEmpty)
          ? DateTime.tryParse(liveState.arriveAt!)?.toLocal()
          : (liveState.etaMin != null
                ? DateTime.now().add(Duration(minutes: liveState.etaMin!))
                : null);
      // The active ride is another one than ours: ours is over (an old ride
      // opened from a notification must not turn into the current one).
      final ours = state.jobId;
      if (ours != null && ours.isNotEmpty && liveState.id != ours) {
        await _resolveEnded(ours);
        return;
      }
      state = state.copyWith(
        isLoading: false,
        jobId: liveState.id,
        driverId: liveState.driverId,
        driverName: liveState.driverJobInfo?.fullName,
        vehiclePlate: liveState.driverJobInfo?.vehiclePlate,
        vehicleProvince: liveState.driverJobInfo?.vehicleProvince,
        vehicleColor: liveState.driverJobInfo?.vehicleColor,
        vehicleType: liveState.driverJobInfo?.vehicleModel,
        driverRating: liveState.driverJobInfo?.rating,
        jobStatus: liveState.status,
        fare: liveState.fare,
        discount: liveState.discount,
        paymentMethod: liveState.paymentMethod,
        amountDue: liveState.amountDue,
        estimatedCancelFee: liveState.estimatedCancelFee,
        etaArriveAt: resyncEta,
        driverProfile: DriverProfileModel.fromActiveJob(liveState),
      );

      // Pay-at-destination (dev14): a PROMPTPAY ride is charged when the trip
      // ends. Watch for the driver opening a collection intent on the final leg
      // and surface the QR to the customer. Keyed off the intent existing (not a
      // status string) so it's robust to the exact payment_status value.
      unawaited(_checkDestinationPayment(liveState.paymentStatus));

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
      if (!ref.mounted) return;
      // No active job yet (still searching for a driver) is expected while
      // polling — don't treat it as an error or log noise.
      final noActiveJob = e.toString().contains('NO_ACTIVE_JOB');
      if (noActiveJob) {
        if (!silent) state = state.copyWith(isLoading: false);
        final ours = state.jobId;
        if (ours != null &&
            ours.isNotEmpty &&
            isRideActiveStatus(state.jobStatus) &&
            await _resolveEnded(ours)) {
          return;
        }
        if (!ref.mounted) return;
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

  /// Our ride dropped off the active list: reads its own status, so a ride
  /// cancelled (by the driver, or the system for want of one) or finished
  /// while the app wasn't listening ends here instead of hanging on its last
  /// live state. Returns whether it is over. A ride still searching for a
  /// driver is not on the active list either, and stays.
  Future<bool> _resolveEnded(String jobId) async {
    final String? status;
    try {
      status = await ref
          .read(driverProfileRepositoryProvider)
          .getJobStatus(jobId);
    } catch (e) {
      debugPrint('LiveRideController: ride status unreadable: $e');
      return false;
    }
    if (!ref.mounted) return false;
    if (state.jobId != jobId || isRideActiveStatus(status)) return false;
    state = state.copyWith(isLoading: false, jobStatus: status ?? 'CANCELLED');
    return true;
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

  /// Pay-at-destination detection (dev14). For a PROMPTPAY ride, the driver
  /// opens a collection intent when the trip ends; the customer then pays by QR
  /// on their own phone. We surface the QR by watching for that intent to exist
  /// (via GET /payment/intent/job/:id) rather than a specific status string, and
  /// latch [LiveRideState.awaitingPromptPay] so the screen routes to the QR once.
  /// Cleared on PAID so it never re-triggers after the customer has paid.
  Future<void> _checkDestinationPayment(String paymentStatus) async {
    // Driver switched the ride to cash (SCRUM-121): the method is no longer
    // PROMPTPAY, so drop any pending-QR latch — the QR screen closes itself on
    // the voided intent, and the live screen must stop expecting a QR payment.
    if (state.paymentMethod.toUpperCase() != 'PROMPTPAY') {
      if (state.awaitingPromptPay) {
        state = state.copyWith(awaitingPromptPay: false);
      }
      return;
    }
    if (paymentStatus.toUpperCase() == 'PAID') {
      if (state.awaitingPromptPay) {
        state = state.copyWith(awaitingPromptPay: false);
      }
      return;
    }
    // The intent is opened on the final leg (PICKED_UP → COMPLETED); don't poll
    // earlier. Once surfaced, stop re-checking until PAID clears it above.
    if (state.jobStatus?.toUpperCase() != 'PICKED_UP') return;
    if (state.awaitingPromptPay) return;
    final jobId = state.jobId;
    if (jobId == null || jobId.isEmpty) return;
    try {
      final intent =
          await ref.read(paymentRepositoryProvider).getIntentByJob(jobId);
      if (intent == null) return; // driver hasn't opened collection yet
      // Any terminal intent (paid, or voided when the driver switches to cash)
      // clears the latch; only a live, non-terminal intent surfaces the QR.
      if (intent.status.isTerminal) {
        if (state.awaitingPromptPay) {
          state = state.copyWith(awaitingPromptPay: false);
        }
      } else {
        state = state.copyWith(awaitingPromptPay: true);
      }
    } catch (e) {
      debugPrint('LiveRideController: destination payment check failed: $e');
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
  /// Opens the live screen on [jobId], checking the ride itself first: an
  /// old notification or a stale link can name a ride long over, which must
  /// not show as live, nor pull in whichever ride is active now.
  Future<LiveJobOpening> openJob(String jobId) async {
    final held = state.jobId == jobId;
    // Nothing under way is held: clear it now, so a ride that ended earlier
    // doesn't flash up while this one is read.
    final cleared = !held && !isRideActiveStatus(state.jobStatus);
    if (cleared) state = LiveRideState(jobId: jobId);
    String? status;
    var known = false;
    try {
      status = await ref
          .read(driverProfileRepositoryProvider)
          .getJobStatus(jobId);
      known = true;
    } catch (e) {
      debugPrint('LiveRideController: ride status unreadable: $e');
    }
    if (!ref.mounted) return LiveJobOpening.missing;
    if (known && !isRideActiveStatus(status)) {
      if (cleared && state.jobId == jobId) state = const LiveRideState();
      if (status == null) return LiveJobOpening.missing;
      if (held && isRideActiveStatus(state.jobStatus)) {
        state = state.copyWith(jobStatus: status);
        return LiveJobOpening.ending;
      }
      return LiveJobOpening.ended;
    }
    if (state.jobId != jobId || (!held && !cleared)) {
      // A ride other than the one held: none of that one may show here.
      state = LiveRideState(jobId: jobId, jobStatus: status ?? 'PENDING');
    } else if (status != null) {
      state = state.copyWith(jobStatus: status);
    }
    unawaited(getDriverProfile());
    return LiveJobOpening.live;
  }
}
