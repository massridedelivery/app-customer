import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/utils/ride_payable.dart';
import 'package:customer_app/features/live_ride/domain/models/driver_profile_model.dart';
import 'dart:async';

import 'package:customer_app/core/constants/map_defaults.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/map_marker_providers.dart';
import 'package:customer_app/core/widgets/route_stops.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/booking_map_widget.dart'
    show decodedPolylineProvider;
import 'package:customer_app/core/utils/polyline_decoder.dart';
import 'package:customer_app/features/live_ride/presentation/controllers/live_ride_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:customer_app/features/live_ride/presentation/states/live_ride_state.dart';
import 'package:customer_app/core/services/ride_ongoing_notification.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum RideUIState { finding, confirming, pickupArrived, onTrip }

/// The active job's own route polyline, decoded and memoised (recomputes only
/// when the encoded string changes). The live ride draws this so the route
/// follows the roads; the booking-flow polyline is empty by now.
final _liveRideRoutePointsProvider = Provider.autoDispose<List<LatLng>>((ref) {
  final encoded = ref.watch(
    liveRideControllerProvider.select((s) => s.driverProfile?.polyline),
  );
  if (encoded == null || encoded.isEmpty) return const [];
  return PolylineDecoder.decodePolyline(encoded);
});

class LiveRideScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const LiveRideScreen({super.key, this.jobId});

  @override
  ConsumerState<LiveRideScreen> createState() => _LiveRideScreenState();
}

class _LiveRideScreenState extends ConsumerState<LiveRideScreen> {
  GoogleMapController? _mapController;

  /// Safety buffer added to the backend ETA before display (shared with the
  /// ride notification so both show the same arrival).
  static const int _kEtaBufferMinutes = kRideEtaBufferMinutes;

  // Prompts the customer to keep searching or change service type when no driver
  // is found within [_findingTimeout] of the "finding" screen.
  static const Duration _findingTimeout = Duration(minutes: 3);
  Timer? _findingTimer;
  bool _findingPromptOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.jobId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(liveRideControllerProvider.notifier).initializeWithJob({
          'id': widget.jobId,
        });
      });
    }
  }

  @override
  void dispose() {
    _findingTimer?.cancel();
    super.dispose();
  }

  /// Runs the 3-minute "still searching" timer only while the finding screen is
  /// up. Idempotent — safe to call every build.
  void _manageFindingTimer(RideUIState uiState) {
    if (uiState == RideUIState.finding) {
      if (_findingTimer == null && !_findingPromptOpen) {
        _findingTimer = Timer(_findingTimeout, _onFindingTimeout);
      }
    } else {
      _findingTimer?.cancel();
      _findingTimer = null;
    }
  }

  Future<void> _onFindingTimeout() async {
    _findingTimer = null;
    if (!mounted) return;
    final st = ref.read(liveRideControllerProvider);
    final hasDriver = st.driverId?.isNotEmpty ?? false;
    // A driver showed up (or the job moved on) right as the timer fired — nothing
    // to prompt.
    if (_getUIState(st.jobStatus, hasDriver: hasDriver) !=
        RideUIState.finding) {
      return;
    }
    _findingPromptOpen = true;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.liveNoDriverTitle),
        content: Text(AppLocalizations.of(ctx)!.liveNoDriverBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('retry'),
            child: Text(AppLocalizations.of(ctx)!.liveKeepSearching),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('change'),
            child: Text(
              AppLocalizations.of(ctx)!.liveChangeService,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    _findingPromptOpen = false;
    if (!mounted) return;
    if (choice == 'change') {
      await _cancelRide(ref.read(liveRideControllerProvider));
    } else {
      // Keep searching — a rebuild restarts the timer via _manageFindingTimer.
      setState(() {});
    }
  }

  void _fitMapToMarkers(LatLng pickup, LatLng dropoff) {
    if (_mapController == null) return;

    double minLat = pickup.latitude < dropoff.latitude
        ? pickup.latitude
        : dropoff.latitude;
    double maxLat = pickup.latitude > dropoff.latitude
        ? pickup.latitude
        : dropoff.latitude;
    double minLng = pickup.longitude < dropoff.longitude
        ? pickup.longitude
        : dropoff.longitude;
    double maxLng = pickup.longitude > dropoff.longitude
        ? pickup.longitude
        : dropoff.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  RideUIState _getUIState(String? status, {bool hasDriver = false}) {
    switch (status?.toUpperCase()) {
      case 'CANCELLED':
        return RideUIState.finding;
      case 'ACCEPTED':
        return RideUIState.confirming;
      case 'ARRIVED_AT_PICK_UP':
        return RideUIState.pickupArrived;
      case 'PICKED_UP':
      case 'COMPLETED':
        return RideUIState.onTrip;
      case 'PENDING':
      default:
        // Defensive: if a driver is already assigned (backend may report an
        // unmapped status string), leave the "finding" screen anyway.
        return hasDriver ? RideUIState.confirming : RideUIState.finding;
    }
  }

  String _getJobIdLabel() {
    // jobId is a backend UUID; show only a short, readable tail rather than the
    // whole string (falls back to a dash before the id is known).
    final id = widget.jobId;
    if (id == null || id.isEmpty) return '—';
    final tail = id.replaceAll('-', '');
    return tail.length <= 6
        ? tail.toUpperCase()
        : tail.substring(tail.length - 6).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Rebuild the sheet on DISCRETE state changes only. driverLocation ticks
    // ~every 2s over the socket and is consumed solely by the map's driver
    // marker (_LiveRideMap watches it in isolation), so it is deliberately
    // excluded from this projection — otherwise the whole sheet re-rendered
    // twice a second. Everything the sheet actually reads is listed here;
    // `read` then grabs the full object to pass down.
    ref.watch(
      liveRideControllerProvider.select(
        (s) => (
          s.jobStatus,
          s.driverId,
          s.isLoading,
          s.error,
          s.driverProfile,
          s.driverName,
          s.driverRating,
          s.vehicleType,
          s.vehiclePlate,
          s.fare,
        ),
      ),
    );
    final liveState = ref.read(liveRideControllerProvider);
    // Select only what this screen renders from home state — a whole-state
    // watch would rebuild the map on every unrelated HomeState change.
    final pickupLocation = ref.watch(
      homeControllerProvider.select((s) => s.pickupLocation),
    );
    final dropoffLocation = ref.watch(
      homeControllerProvider.select((s) => s.dropoffLocation),
    );
    final pickupAddress = ref.watch(
      homeControllerProvider.select((s) => s.pickupAddress),
    );
    final dropoffAddress = ref.watch(
      homeControllerProvider.select((s) => s.dropoffAddress),
    );
    final bookingAsync = ref.watch(bookingControllerProvider);
    final bookingState = bookingAsync.value ?? const BookingState();
    // Prefer the active job's own route polyline (follows the roads); fall back
    // to the booking-estimate polyline, which is empty once the booking flow
    // has ended — that fallback is what left the map drawing a straight
    // pickup→dropoff line.
    final jobRoutePoints = ref.watch(_liveRideRoutePointsProvider);
    final routePoints = jobRoutePoints.isNotEmpty
        ? jobRoutePoints
        : ref.watch(decodedPolylineProvider);
    // App-wide cached marker bitmaps (rasterised once per session).
    final pickupIcon = ref.watch(pickupMarkerProvider).value;
    final dropoffIcon = ref.watch(dropoffMarkerProvider).value;
    final driverIcon = ref.watch(vehicleMarkerProvider).value;
    final hasDriver = liveState.driverId?.isNotEmpty ?? false;
    final uiState = _getUIState(liveState.jobStatus, hasDriver: hasDriver);
    _manageFindingTimer(uiState);

    ref.listen(liveRideControllerProvider, (previous, next) {
      // Mirror the ride into the Android "ride in progress" notification.
      ref.read(rideOngoingNotificationProvider).sync(next);
      if ((next.jobStatus == 'CANCELLED' &&
              previous?.jobStatus != 'CANCELLED') ||
          (next.jobStatus == 'COMPLETED' &&
              previous?.jobStatus != 'COMPLETED')) {
        final isCompleted = next.jobStatus == 'COMPLETED';

        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            // The job is terminal (completed/cancelled) — drop the recovery
            // redirect so the router doesn't yank us back to /live on the way
            // to the payment summary or home.
            ref.read(authControllerProvider.notifier).clearActiveJob();
            if (isCompleted && next.jobId != null) {
              context.pushReplacement(
                '/payment-summary/${next.jobId}',
                extra: next.driverProfile,
              );
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/main');
              }
            }
          }
        });

        final cancelFee = next.chargedCancelFee ?? 0;
        final reason = next.cancelReason;
        final String cancelMsg;
        if (reason != null && reason.isNotEmpty) {
          // System-initiated cancel (SCRUM-111): frame it as the system helping,
          // not as an error the user caused.
          cancelMsg = reason == 'driver_unavailable'
              ? l10n.liveAutoCancelNoDriver
              : l10n.liveAutoCancelled;
        } else if (cancelFee > 0) {
          cancelMsg = l10n.liveCancelledWithFee(cancelFee.toStringAsFixed(0));
        } else {
          cancelMsg = l10n.rideCancelled;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.jobStatus == 'COMPLETED' ? l10n.rideCompleted : cancelMsg,
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    // Pay-at-destination (dev14): once the driver opens the collection intent at
    // the end of a PROMPTPAY ride, surface the QR so the customer pays on their
    // own phone. On PAID the QR screen returns to live; the driver then completes
    // the ride, which routes to the summary above.
    ref.listen(liveRideControllerProvider.select((s) => s.awaitingPromptPay), (
      wasAwaiting,
      isAwaiting,
    ) {
      if (isAwaiting && !(wasAwaiting ?? false)) {
        final jobId = ref.read(liveRideControllerProvider).jobId;
        if (jobId != null && context.mounted) {
          context.push(
            '/payment/promptpay',
            extra: {'jobId': jobId, 'onPaidRoute': '/live/$jobId'},
          );
        }
      }
    });

    final pickup = pickupLocation ?? MapDefaults.bangkokCenter;
    // Fall back to the same named default as pickup instead of an arbitrary
    // hardcoded coordinate when the destination isn't restored yet.
    final dropoff = dropoffLocation ?? MapDefaults.bangkokCenter;

    // Shared bottom-sheet content, reused by both the fixed finding-mode panel
    // and the draggable confirmed-mode sheet.
    final sheetInner = uiState == RideUIState.finding
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status card (messenger-style): title + subtitle + icon timeline
              // + id, while we still look for a driver.
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderTitle(uiState, liveState.jobStatus),
                    const SizedBox(height: 16),
                    _buildTimeline(uiState),
                    const SizedBox(height: 12),
                    Text(
                      l10n.liveTripNumber(_getJobIdLabel()), // Job ID
                      style: AppTypography.caption5.copyWith(
                        color: AppColors.semanticGrayNeutralFgLowOnWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildFindingModeContent(
                pickupAddress,
                dropoffAddress,
                bookingState,
                liveState,
              ),
            ],
          )
        : _buildConfirmedModeContent(
            uiState,
            pickupAddress,
            dropoffAddress,
            liveState,
          );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bottom Layer: Map (Visible after finding driver). Extracted so the
          // ~2s driver-location updates rebuild ONLY the map, not this whole
          // screen / bottom sheet.
          // Map with the pickup→dropoff route, shown in every state (incl.
          // finding) so the ride mirrors the messenger tracking UI — a live map
          // under a draggable card sheet, not a static illustration.
          Positioned.fill(
            child: _LiveRideMap(
              pickup: pickup,
              dropoff: dropoff,
              pickupIcon: pickupIcon,
              dropoffIcon: dropoffIcon,
              driverIcon: driverIcon,
              routePoints: routePoints,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitMapToMarkers(pickup, dropoff);
              },
            ),
          ),

          // Draggable card sheet over the map (messenger-style) for all states.
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.5, 0.85],
              builder: (context, scrollController) {
                return Container(
                  decoration: _sheetDecoration,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(bottom: 30 + MediaQuery.paddingOf(context).bottom),
                    children: [
                      _buildGrabHandle(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: sheetInner,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Top action buttons (Close & Cancel)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    // Escape hatch: drop the recovery redirect first, otherwise
                    // the router forces us straight back to /live while an
                    // active job is set — a stale/stuck job (e.g. one the
                    // backend never closes) would trap the user here with no
                    // way out. A genuine active ride is still reachable from the
                    // home banner and re-recovers on the next app launch.
                    ref.read(authControllerProvider.notifier).clearActiveJob();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/main');
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.semanticGrayNeutralFgHigh,
                    ),
                  ),
                ),
                if (uiState == RideUIState.finding &&
                    liveState.jobStatus != 'CANCELLED')
                  GestureDetector(
                    onTap: liveState.isLoading
                        ? null
                        : () => _cancelRide(liveState),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: liveState.isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              uiState == RideUIState.finding
                                  ? l10n.cancelSearch
                                  : l10n.liveCancelRide,
                              style: AppTypography.caption4.copyWith(
                                color: AppColors.semanticGrayNeutralFgHigh,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRide(dynamic liveState) async {
    // Cancelling after a driver has accepted may incur a cancellation fee. Show
    // the real amount from the backend (estimated_cancel_fee, SCRUM-65) rather
    // than a vague warning.
    final st = ref.read(liveRideControllerProvider);
    final hasDriver = st.driverId?.isNotEmpty ?? false;
    if (hasDriver) {
      final l10n = AppLocalizations.of(context)!;
      final fee = st.estimatedCancelFee ?? 0;
      final content = fee > 0
          ? l10n.liveCancelFeeConfirm(fee.toStringAsFixed(0))
          : l10n.liveCancelMayFeeConfirm;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.liveCancelRideQuestion),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.liveNo),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                l10n.liveConfirmCancel,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // What the cancel gives back (the backend refunds it by itself).
    final pointsUsed = st.driverProfile?.pointsUsed ?? 0;
    final code = ref.read(bookingControllerProvider).value?.appliedPromoCode;
    final usedVoucher = code?.toUpperCase().startsWith('RW-') ?? false;
    final success = await ref
        .read(liveRideControllerProvider.notifier)
        .cancelRide();
    if (success && (pointsUsed > 0 || usedVoucher)) {
      ref.invalidate(loyaltySummaryProvider);
      ref.invalidate(vouchersProvider);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              [
                if (pointsUsed > 0)
                  l10n.pointsRefundedOnCancel(fmtPoints(pointsUsed)),
                if (usedVoucher) l10n.voucherRefundedOnCancel,
              ].join(' · '),
            ),
          ),
        );
      }
    }
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            liveState.error ?? AppLocalizations.of(context)!.cancelFailed,
          ),
        ),
      );
    }
  }

  /// White, rounded, bordered card wrapper — matches the messenger tracking
  /// cards so the ride sheet reads as the same stack of cards.
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.foundationGrayscale200),
      ),
      child: child,
    );
  }

  // Shared white, rounded-top sheet surface with a soft top shadow.
  static const BoxDecoration _sheetDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    ),
    boxShadow: [
      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
    ],
  );

  Widget _buildGrabHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(RideUIState state, String? status) {
    final l10n = AppLocalizations.of(context)!;
    String title = '';
    String subtitle = '';

    if (status == 'CANCELLED') {
      title = l10n.rideCancelled;
      subtitle = l10n.liveTripCancelledSub;
    } else {
      switch (state) {
        case RideUIState.finding:
          title = l10n.searchingDriver;
          subtitle = l10n.liveFindingNearYou;
          break;
        case RideUIState.confirming:
          title = l10n.liveDriverOnTheWay;
          subtitle = l10n.liveWaitAtPickup;
          break;
        case RideUIState.pickupArrived:
          title = l10n.driverArrived;
          subtitle = l10n.livePleaseBoard;
          break;
        case RideUIState.onTrip:
          title = l10n.liveHeadingToDestTitle;
          subtitle = l10n.headingToDest;
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading3.copyWith(
            color: AppColors.foundationGreen700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.caption4.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(RideUIState state) {
    // finding → step 0 (person_search active, first line animating), matching
    // the messenger tracking timeline so both flows read the same.
    int activeStep = 0;
    switch (state) {
      case RideUIState.finding:
        activeStep = 0;
        break;
      case RideUIState.confirming:
      case RideUIState.pickupArrived:
        activeStep = 1;
        break;
      case RideUIState.onTrip:
        activeStep = 2;
        break;
    }

    return Row(
      children: [
        _buildTimelineIcon(Icons.person_search, 0 <= activeStep, isBox: true),
        _buildTimelineLine(
          isBlue: 0 < activeStep,
          isAnimating: 0 == activeStep,
        ),
        _buildTimelineIcon(Icons.directions_car, 1 <= activeStep),
        _buildTimelineLine(
          isBlue: 1 < activeStep,
          isAnimating: 1 == activeStep,
        ),
        _buildTimelineIcon(Icons.location_on, 2 <= activeStep),
      ],
    );
  }

  Widget _buildTimelineIcon(
    IconData icon,
    bool isActive, {
    bool isBox = false,
  }) {
    Color color = isActive
        ? AppColors.foundationGreen600
        : Colors.grey.shade400;
    if (isBox) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      );
    }
    return Icon(icon, size: 24, color: color);
  }

  Widget _buildTimelineLine({required bool isBlue, bool isAnimating = false}) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: isAnimating
              ? LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.foundationGreen600,
                  ),
                )
              : Container(
                  color: isBlue
                      ? AppColors.foundationGreen600
                      : Colors.grey.shade200,
                ),
        ),
      ),
    );
  }

  Widget _buildFindingModeContent(
    String? pickupAddress,
    String? dropoffAddress,
    dynamic bookingState,
    dynamic liveState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationDetailsSection(pickupAddress, dropoffAddress),
        const SizedBox(height: 16),
        _buildRideSummarySection(bookingState, liveState),
        const SizedBox(height: 16),
        _buildPaymentMethodSection(),
      ],
    );
  }

  /// Driver assigned (design R1): status + ETA, the driver card with a big
  /// plate, chat/call, the route, payment + total, and the cancel button while
  /// the rider has not been picked up.
  Widget _buildConfirmedModeContent(
    RideUIState uiState,
    String? pickupAddress,
    String? dropoffAddress,
    LiveRideState liveState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final canCancel =
        uiState != RideUIState.onTrip && liveState.jobStatus != 'CANCELLED';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusHeader(uiState, liveState, pickupAddress, dropoffAddress),
        const SizedBox(height: 14),
        _buildRideSteps(liveState.jobStatus, liveState.vehicleType),
        const SizedBox(height: 16),
        _buildRiderSection(liveState),
        const SizedBox(height: 12),
        _buildLocationDetailsSection(pickupAddress, dropoffAddress),
        const SizedBox(height: 12),
        _buildPayTotalSection(liveState),
        if (canCancel) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              key: const Key('liveCancelButton'),
              onPressed: liveState.isLoading
                  ? null
                  : () => _cancelRide(liveState),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFDF1F3),
                foregroundColor: AppColors.primary,
                shape: const StadiumBorder(),
              ),
              child: liveState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.liveCancelRide,
                      style: AppTypography.label1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: Text(
            l10n.liveTripNumber(_getJobIdLabel()),
            style: AppTypography.caption5.copyWith(
              color: AppColors.semanticGrayNeutralFgLowOnWhite,
            ),
          ),
        ),
      ],
    );
  }

  /// Minutes until the driver reaches the current target, padded with the
  /// safety buffer; null until the backend sends an ETA.
  int? _etaMinutes(LiveRideState liveState) {
    final raw = liveState.etaArriveAt;
    if (raw == null) return null;
    final arriveAt = raw.add(const Duration(minutes: _kEtaBufferMinutes));
    final diff = arriveAt.difference(DateTime.now()).inMinutes;
    return diff < 1 ? 1 : diff;
  }

  /// "คนขับกำลังมา · ที่อยู่" on the left, "3 นาที" on the right.
  Widget _buildStatusHeader(
    RideUIState uiState,
    LiveRideState liveState,
    String? pickupAddress,
    String? dropoffAddress,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final completed = liveState.jobStatus?.toUpperCase() == 'COMPLETED';
    final title = completed
        ? l10n.rideCompleted
        : switch (uiState) {
            RideUIState.pickupArrived => l10n.driverArrived,
            RideUIState.onTrip => l10n.liveHeadingToDestTitle,
            _ => l10n.liveDriverOnTheWay,
          };
    final place = uiState == RideUIState.onTrip
        ? dropoffAddress
        : pickupAddress;
    // No countdown once the driver is waiting at pickup or the ride is over.
    final minutes = uiState == RideUIState.pickupArrived || completed
        ? null
        : _etaMinutes(liveState);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.heading3),
              if (place != null && place.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgLowOnWhite,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (minutes != null) ...[
          const SizedBox(width: 12),
          Text(
            '$minutes ${l10n.minutes}',
            key: const Key('liveEtaMinutes'),
            style: AppTypography.heading3,
          ),
        ],
      ],
    );
  }

  /// Opens the phone dialer with the driver's number (free, uses the mobile
  /// network). No masked/VoIP layer yet — the rider sees the real number.
  Future<void> _callDriver(String? phone) async {
    final number = (phone ?? '').trim();
    if (number.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.liveNoDriverPhone),
          ),
        );
      }
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: number));
  }

  /// Four-step progress under the R1 header: กำลังมา → ถึงจุดรับ →
  /// กำลังเดินทาง → ถึงแล้ว, each with its own icon (Remix Icon fill set). Done and current steps are
  /// green with a white icon, later ones grey outlines; the lines between done
  /// steps are solid green and the line leaving the current step flows (an
  /// indeterminate bar) so the rider sees the ride moving towards the next one.
  Widget _buildRideSteps(String? status, String? vehicleType) {
    final l10n = AppLocalizations.of(context)!;
    final active = switch (status?.toUpperCase()) {
      'ARRIVED_AT_PICK_UP' => 1,
      'PICKED_UP' => 2,
      'COMPLETED' => 3,
      _ => 0,
    };
    final labels = [
      l10n.rideStepComing,
      l10n.rideStepArrived,
      l10n.rideStepOnTrip,
      l10n.rideStepDone,
    ];
    const green = AppColors.foundationGreen600;
    final grey = Colors.grey.shade300;

    final type = (vehicleType ?? '').toLowerCase();
    final icons = [
      type.contains('bike') || type.contains('motor')
          ? AppAssets.icStepBike
          : AppAssets.icStepCar,
      AppAssets.icStepPickup,
      AppAssets.icStepRoute,
      AppAssets.icStepFinish,
    ];

    Widget dot(int i) {
      final reached = i <= active;
      final current = i == active && active != 3;
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reached ? green : Colors.white,
          border: Border.all(color: reached ? green : grey, width: 2),
          boxShadow: current
              ? [
                  BoxShadow(
                    color: green.withValues(alpha: 0.25),
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: SvgPicture.asset(
            icons[i],
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              reached ? Colors.white : Colors.grey.shade400,
              BlendMode.srcIn,
            ),
          ),
        ),
      );
    }

    Widget line(int i) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: i == active && active != 3
                ? LinearProgressIndicator(
                    backgroundColor: grey,
                    valueColor: const AlwaysStoppedAnimation(green),
                  )
                : ColoredBox(color: i < active ? green : grey),
          ),
        ),
      ),
    );

    return Column(
      key: const Key('liveRideSteps'),
      children: [
        // Inset the dots so each one sits at the centre of its label's
        // quarter-width column below (centres at 1/8, 3/8, 5/8, 7/8).
        LayoutBuilder(
          builder: (context, constraints) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth / 8 - 15,
            ),
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[dot(i), if (i < 3) line(i)],
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption5.copyWith(
                    color: i <= active
                        ? AppColors.semanticGrayNeutralFgHigh
                        : AppColors.semanticGrayNeutralFgLowOnWhite,
                    fontWeight: i == active
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiderSection(LiveRideState liveState) {
    final l10n = AppLocalizations.of(context)!;
    final avatarUrl = liveState.driverProfile?.driverInfo.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final type = (liveState.vehicleType ?? '').toLowerCase();
    final isBike = type.contains('bike') || type.contains('motor');
    final plate = liveState.vehiclePlate ?? '';
    // Only join the parts we actually have — no "null · null" before the
    // vehicle details arrive.
    final vehicle = [
      liveState.vehicleColor,
      liveState.vehicleType,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.foundationGrayscale200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF1F2F5),
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                child: hasAvatar
                    ? null
                    : const Icon(
                        Icons.person,
                        color: AppColors.semanticGrayNeutralFgLowOnWhite,
                        size: 30,
                      ),
              ),
              Transform.translate(
                offset: const Offset(-12, 0),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF1F3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    isBike ? Icons.two_wheeler : Icons.directions_car,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (plate.isNotEmpty)
                      Text(
                        plate,
                        key: const Key('livePlate'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.heading2.copyWith(
                          fontSize: 24,
                          letterSpacing: 1,
                        ),
                      ),
                    if (vehicle.isNotEmpty)
                      Text(
                        vehicle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.semanticGrayNeutralFgLowOnWhite,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Text(
                  liveState.driverName ?? l10n.assigningDriver,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body2,
                ),
              ),
              if (liveState.driverRating != null) ...[
                Text(
                  ' · ${liveState.driverRating!.toStringAsFixed(1)} ',
                  style: AppTypography.body2,
                ),
                const Icon(Icons.star, color: Colors.amber, size: 16),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  shape: const StadiumBorder(
                    side: BorderSide(color: AppColors.foundationGrayscale200),
                  ),
                  child: InkWell(
                    key: const Key('liveChatButton'),
                    customBorder: const StadiumBorder(),
                    onTap: () {
                      if (widget.jobId != null) {
                        context.push('/chat/${widget.jobId}');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: AppColors.semanticGrayNeutralFgLowOnWhite,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.liveChatWithDriver,
                            style: AppTypography.body2.copyWith(
                              color: AppColors.semanticGrayNeutralFgLowOnWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.white,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.foundationGrayscale200),
                ),
                child: InkWell(
                  key: const Key('liveCallButton'),
                  customBorder: const CircleBorder(),
                  onTap: () =>
                      _callDriver(liveState.driverProfile?.driverInfo.phone),
                  child: const SizedBox.square(
                    dimension: 48,
                    child: Icon(
                      Icons.phone_outlined,
                      size: 22,
                      color: AppColors.semanticGrayNeutralFgHigh,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Payment method on the left, what the rider pays on the right, with the
  /// coupon discount above it when there is one.
  Widget _buildPayTotalSection(LiveRideState liveState) {
    final l10n = AppLocalizations.of(context)!;
    final method =
        (ref.watch(bookingControllerProvider).value?.paymentMethod ?? 'CASH')
            .toUpperCase();
    final (label, icon) = switch (method) {
      'PROMPTPAY' => (l10n.promptPay, Icons.qr_code_2_rounded),
      'CARD' => (l10n.livePayCard, Icons.credit_card_rounded),
      _ => (l10n.cashLabel, Icons.payments_outlined),
    };
    final discount = _rideDiscount(liveState);
    final priorFee = _priorCancelFee(liveState);
    final payable = _ridePayable(liveState);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.foundationGrayscale200),
      ),
      child: Column(
        children: [
          if (discount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.couponDiscount,
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '−฿${discount.toStringAsFixed(0)}',
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (priorFee > 0) ...[
            _priorCancelFeeRow(priorFee),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(icon, size: 22, color: AppColors.foundationGreen600),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: AppTypography.body2)),
              Text(
                payable == null ? '฿--' : '฿${payable.toStringAsFixed(0)}',
                key: const Key('livePayable'),
                style: AppTypography.heading3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetailsSection(
    String? pickupAddress,
    String? dropoffAddress,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: RouteStops(
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
      ),
    );
  }

  /// Coupon discount on the live job (0 when none).
  double _rideDiscount(dynamic liveState) {
    final DriverProfileModel? profile = liveState.driverProfile;
    return profile?.discount ?? (liveState.discount as double?) ?? 0;
  }

  /// Unpaid cancellation fee from an earlier ride that this one carries
  /// (already inside amount_due); 0 when none.
  double _priorCancelFee(dynamic liveState) {
    final DriverProfileModel? profile = liveState.driverProfile;
    return profile?.priorCancelFee ?? 0;
  }

  Widget _priorCancelFeeRow(double fee) {
    final l10n = AppLocalizations.of(context)!;
    final style = AppTypography.caption3.copyWith(
      color: AppColors.semanticGrayNeutralFgLowOnWhite,
    );
    return Row(
      key: const Key('livePriorCancelFee'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(l10n.ridePriorCancelFee, style: style)),
        Text('+฿${fee.toStringAsFixed(0)}', style: style),
      ],
    );
  }

  /// What the rider pays (see [ridePayable]); null until the fare is known.
  double? _ridePayable(dynamic liveState) {
    final DriverProfileModel? profile = liveState.driverProfile;
    // Same figure the driver sees (dev102 amount_due) once the job is synced.
    if (profile != null) return profile.payable;
    final double? fare = liveState.fare as double?;
    if (fare == null) return null;
    return ridePayable(
      fare: fare,
      discount: _rideDiscount(liveState),
      tollFee: profile?.tollFee ?? 0,
      waitingFee: profile?.waitingFee ?? 0,
    );
  }

  Widget _buildRideSummarySection(dynamic bookingState, dynamic liveState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.liveTripSummary,
            style: AppTypography.label2,
          ),
          const SizedBox(height: 12),
          // Always visible: distance now; travel time only appears once the ride
          // is underway (PICKED_UP), as a live Google ETA to the destination.
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  AppLocalizations.of(context)!.distance,
                  '${bookingState.distanceKm?.toStringAsFixed(1) ?? '--'} ${AppLocalizations.of(context)!.km}',
                ),
              ),
              if ((liveState.jobStatus as String?)?.toUpperCase() ==
                      'PICKED_UP' &&
                  liveState.etaArriveAt != null)
                Expanded(
                  child: _buildStatColumn(
                    AppLocalizations.of(context)!.etaExpectedArrival,
                    AppDates.of(context).time(
                      (liveState.etaArriveAt as DateTime).add(
                        const Duration(minutes: _kEtaBufferMinutes),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // The job's `fare` is the price before the coupon; what the rider
          // pays is fare - discount (+ tolls / waiting once charged).
          if (_rideDiscount(liveState) > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.couponDiscount,
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.foundationGreen600,
                  ),
                ),
                Text(
                  '-฿${_rideDiscount(liveState).toStringAsFixed(0)}',
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.foundationGreen600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (_priorCancelFee(liveState) > 0) ...[
            _priorCancelFeeRow(_priorCancelFee(liveState)),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.liveTotalFare,
                style: AppTypography.label1,
              ),
              Text(
                _ridePayable(liveState) == null
                    ? '฿--'
                    : '฿${_ridePayable(liveState)!.toStringAsFixed(0)}',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.foundationGreen600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption5.copyWith(
            color: AppColors.semanticGrayNeutralFgLowOnWhite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.caption3.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    final l10n = AppLocalizations.of(context)!;
    final method =
        (ref.watch(bookingControllerProvider).value?.paymentMethod ?? 'CASH')
            .toUpperCase();
    final isPromptPay = method == 'PROMPTPAY';
    final isCard = method == 'CARD';
    final label = isPromptPay
        ? l10n.promptPay
        : isCard
        ? l10n.livePayCard
        : l10n.cashLabel;
    final badgeBg = isPromptPay
        ? AppColors.foundationBlue100
        : isCard
        ? AppColors.foundationViolet100
        : AppColors.foundationGreen100;
    final badgeFg = isPromptPay
        ? AppColors.foundationBlue800
        : isCard
        ? AppColors.foundationViolet800
        : AppColors.foundationGreen700;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                l10n.livePaymentMethod,
                style: AppTypography.caption4.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: AppTypography.caption5.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The live map, isolated so the ~2s driver-location socket updates rebuild
/// only this widget's marker set — not the surrounding screen and bottom sheet.
/// The stable inputs (pickup/dropoff/icons/route) come in as params; the
/// frequently-changing driver position is watched here.
class _LiveRideMap extends ConsumerWidget {
  final LatLng pickup;
  final LatLng dropoff;
  final BitmapDescriptor? pickupIcon;
  final BitmapDescriptor? dropoffIcon;
  final BitmapDescriptor? driverIcon;
  final List<LatLng> routePoints;
  final void Function(GoogleMapController) onMapCreated;

  const _LiveRideMap({
    required this.pickup,
    required this.dropoff,
    required this.pickupIcon,
    required this.dropoffIcon,
    required this.driverIcon,
    required this.routePoints,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverLocation = ref.watch(
      liveRideControllerProvider.select((s) => s.driverLocation),
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: pickup, zoom: 14.0),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      padding: const EdgeInsets.only(bottom: 350, top: 40),
      onMapCreated: onMapCreated,
      markers: {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon:
              pickupIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff,
          icon:
              dropoffIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        if (driverLocation != null)
          Marker(
            markerId: const MarkerId('driver'),
            position: driverLocation,
            anchor: const Offset(0.5, 0.5),
            icon:
                driverIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
          ),
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          // Memoized decode shared via decodedPolylineProvider.
          points: routePoints.isNotEmpty ? routePoints : [pickup, dropoff],
          color: AppColors.accentRedDeep,
          width: 4,
        ),
      },
    );
  }
}
