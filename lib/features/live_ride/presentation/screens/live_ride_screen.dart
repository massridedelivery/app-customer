import 'dart:async';

import 'package:customer_app/core/constants/map_defaults.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/map_marker_providers.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/booking_map_widget.dart'
    show decodedPolylineProvider;
import 'package:customer_app/core/utils/polyline_decoder.dart';
import 'package:customer_app/features/live_ride/presentation/controllers/live_ride_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
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

  /// Safety buffer added to the backend ETA before display, so we under-promise
  /// (the rider tends to arrive a little earlier than shown).
  static const int _kEtaBufferMinutes = 15;

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
    if (_getUIState(st.jobStatus, hasDriver: hasDriver) != RideUIState.finding) {
      return;
    }
    _findingPromptOpen = true;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยังหาคนขับให้ไม่ได้'),
        content: const Text(
          'ตอนนี้ยังไม่พบคนขับที่ว่างรับงาน '
          'ต้องการค้นหาต่อ หรือเปลี่ยนประเภทบริการ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('retry'),
            child: const Text('ค้นหาต่อ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('change'),
            child: const Text(
              'เปลี่ยนประเภทบริการ',
              style: TextStyle(color: AppColors.primary),
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
      if ((next.jobStatus == 'CANCELLED' &&
              previous?.jobStatus != 'CANCELLED') ||
          (next.jobStatus == 'COMPLETED' &&
              previous?.jobStatus != 'COMPLETED')) {
        final isCompleted = next.jobStatus == 'COMPLETED';

        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
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
        final cancelMsg = cancelFee > 0
            ? 'ยกเลิกการเดินทางแล้ว • มีค่าบริการยกเลิก ฿${cancelFee.toStringAsFixed(0)}'
            : l10n.rideCancelled;
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

    final pickup = pickupLocation ?? MapDefaults.bangkokCenter;
    // Fall back to the same named default as pickup instead of an arbitrary
    // hardcoded coordinate when the destination isn't restored yet.
    final dropoff = dropoffLocation ?? MapDefaults.bangkokCenter;

    // Shared bottom-sheet content, reused by both the fixed finding-mode panel
    // and the draggable confirmed-mode sheet.
    final sheetInner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderTitle(uiState, liveState.jobStatus),
        const SizedBox(height: 16),
        _buildTimeline(uiState),
        const SizedBox(height: 16),
        Text(
          'เลขการเดินทาง-${_getJobIdLabel()}', // Job ID
          style: AppTypography.caption5.copyWith(
            color: AppColors.semanticGrayNeutralFgLowOnWhite,
          ),
        ),
        const SizedBox(height: 16),
        if (uiState == RideUIState.finding)
          _buildFindingModeContent(
            pickupAddress,
            dropoffAddress,
            bookingState,
            liveState,
          )
        else
          _buildConfirmedModeContent(
            pickupAddress,
            dropoffAddress,
            bookingState,
            liveState,
          ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bottom Layer: Map (Visible after finding driver). Extracted so the
          // ~2s driver-location updates rebuild ONLY the map, not this whole
          // screen / bottom sheet.
          Positioned.fill(
            child: uiState != RideUIState.finding
                ? _LiveRideMap(
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
                  )
                : const SizedBox.shrink(),
          ),

          // Illustration Layer (Visible ONLY during finding/cancelled)
          if (uiState == RideUIState.finding)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.45,
              child: _buildTopIllustration(),
            ),

          // Bottom Sheet Layer. While finding a driver it's a fixed tall panel
          // (the illustration sits above it). Once a driver is confirmed it
          // becomes a draggable sheet the rider can snap between 50% and 80% of
          // the screen height.
          if (uiState == RideUIState.finding)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: _sheetDecoration,
                child: Column(
                  children: [
                    _buildGrabHandle(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 30,
                        ),
                        child: sheetInner,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned.fill(
              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.5,
                maxChildSize: 0.8,
                snap: true,
                snapSizes: const [0.5, 0.8],
                builder: (context, scrollController) {
                  return Container(
                    decoration: _sheetDecoration,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 30),
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
                if ((uiState == RideUIState.finding ||
                        uiState == RideUIState.confirming ||
                        uiState == RideUIState.pickupArrived) &&
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
                                  : 'ยกเลิกการเดินทาง',
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
      final fee = st.estimatedCancelFee ?? 0;
      final content = fee > 0
          ? 'คนขับรับงานแล้ว หากยกเลิกตอนนี้จะมีค่าบริการยกเลิก '
                '฿${fee.toStringAsFixed(0)}\nต้องการยกเลิกหรือไม่?'
          : 'คนขับรับงานแล้ว การยกเลิกตอนนี้อาจมีค่าบริการในการยกเลิก\n'
                'ต้องการยกเลิกหรือไม่?';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ยกเลิกการเดินทาง?'),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ไม่'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'ยืนยันยกเลิก',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final success = await ref
        .read(liveRideControllerProvider.notifier)
        .cancelRide();
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

  Widget _buildTopIllustration() {
    return Container(
      color: const Color(0xFFE3F2FD), // Light Blue like finding mode
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 60,
            child: Opacity(
              opacity: 0.1,
              child: const Icon(Icons.map, size: 160, color: Colors.black),
            ),
          ),
          Positioned(
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Icon(
                Icons.person_search,
                size: 64,
                color: AppColors.accentRedDeep,
              ),
            ),
          ),
        ],
      ),
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
    String title = '';
    String subtitle = '';

    if (status == 'CANCELLED') {
      title = AppLocalizations.of(context)!.rideCancelled;
      subtitle = 'การเดินทางถูกยกเลิกแล้ว';
    } else {
      switch (state) {
        case RideUIState.finding:
          title = AppLocalizations.of(context)!.searchingDriver;
          subtitle = 'กำลังหาคนขับรถที่อยู่ใกล้คุณ...';
          break;
        case RideUIState.confirming:
          title = 'คนขับรถกำลังเดินทางมารับ';
          subtitle = 'โปรดรอที่จุดรับผู้โดยสาร';
          break;
        case RideUIState.pickupArrived:
          title = 'คนขับรถมาถึงแล้ว!';
          subtitle = 'กรุณาขึ้นรถ';
          break;
        case RideUIState.onTrip:
          title = 'กำลังเดินทางไปยังที่หมาย';
          subtitle = 'มุ่งหน้าสู่จุดหมายปลายทาง...';
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
    int activeStep = -1;
    if (state == RideUIState.confirming) activeStep = 0;
    if (state == RideUIState.pickupArrived) activeStep = 1;
    if (state == RideUIState.onTrip) activeStep = 2;

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

  Widget _buildConfirmedModeContent(
    String? pickupAddress,
    String? dropoffAddress,
    dynamic bookingState,
    dynamic liveState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEtaBanner(liveState),
        _buildRiderSection(liveState),
        const SizedBox(height: 16),
        _buildLocationDetailsSection(pickupAddress, dropoffAddress),
        const SizedBox(height: 16),
        _buildRideSummarySection(bookingState, liveState),
        const SizedBox(height: 16),
        _buildPaymentMethodSection(),
      ],
    );
  }

  /// Live "arrives in ~N min · around HH:MM" banner (Grab / LINE MAN style).
  /// Driven by a server-computed arrival time pushed on the socket — the client
  /// counts the minutes down locally, calling no routing API. Copy switches by
  /// phase: driver → pickup before the ride, driver → destination once
  /// PICKED_UP. Hidden until the backend sends an ETA.
  Widget _buildEtaBanner(dynamic liveState) {
    final DateTime? raw = liveState.etaArriveAt;
    if (raw == null) return const SizedBox.shrink();
    // Pad with a safety buffer so we under-promise the arrival.
    final arriveAt = raw.add(const Duration(minutes: _kEtaBufferMinutes));
    final diff = arriveAt.difference(DateTime.now()).inMinutes;
    final minutes = diff < 1 ? 1 : diff;
    final pickedUp =
        (liveState.jobStatus as String?)?.toUpperCase() == 'PICKED_UP';
    final title = pickedUp ? 'กำลังเดินทางไปส่ง' : 'ไรเดอร์กำลังมารับ';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.foundationGreen500.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.foundationGreen500.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.foundationGreen500,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.semanticGrayNeutralFgLowOnWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'อีกประมาณ ',
                        style: AppTypography.label1.copyWith(
                          color: AppColors.foundationGreen600,
                        ),
                      ),
                      Text(
                        '$minutes',
                        style: AppTypography.heading2.copyWith(
                          color: AppColors.foundationGreen600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.minutes,
                        style: AppTypography.label1.copyWith(
                          color: AppColors.foundationGreen600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'คาดว่าถึงประมาณ ${_formatClock(arriveAt)} น.',
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.semanticGrayNeutralFgLowOnWhite,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a [DateTime] as a 24h HH:mm clock.
  String _formatClock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Opens the phone dialer with the driver's number (free, uses the mobile
  /// network). No masked/VoIP layer yet — the rider sees the real number.
  Future<void> _callDriver(String? phone) async {
    final number = (phone ?? '').trim();
    if (number.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบเบอร์โทรของคนขับ')),
        );
      }
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: number));
  }

  Widget _buildRiderSection(dynamic liveState) {
    final avatarUrl = liveState.driverProfile?.driverInfo.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

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
        children: [
          Row(
            children: [
              hasAvatar
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(avatarUrl),
                    )
                  : const Icon(
                      Icons.person,
                      color: AppColors.semanticGrayNeutralFgHigh,
                      size: 32,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liveState.driverName ??
                          AppLocalizations.of(context)!.assigningDriver,
                      style: AppTypography.label2,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          liveState.driverRating?.toStringAsFixed(1) ?? '0.0',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          // Only join the parts we actually have — avoid showing
                          // "null • null" before vehicle details arrive.
                          [liveState.vehicleType, liveState.vehiclePlate]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .join(' • '),
                          style: AppTypography.caption4.copyWith(
                            color: AppColors.semanticGrayNeutralFgLowOnWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.jobId != null) {
                      context.push('/chat/${widget.jobId}');
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('แชท'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentRedDeep,
                    side: BorderSide(color: Colors.grey.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _callDriver(liveState.driverProfile?.driverInfo.phone),
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('โทร'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentRedDeep,
                    side: BorderSide(color: Colors.grey.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcons.asset(
                AppAssets.icLocationFill,
                color: AppColors.foundationGreen500,
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('จุดรับ', style: AppTypography.label2),
                    const SizedBox(height: 4),
                    Text(
                      pickupAddress ?? 'จุดรับ',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgLowOnWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 9),
              child: _DashedVerticalLine(
                height: 24,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcons.asset(
                AppAssets.icLocationFill,
                color: AppColors.foundationRed700,
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('จุดส่ง', style: AppTypography.label2),
                    const SizedBox(height: 4),
                    Text(
                      dropoffAddress ?? 'จุดส่ง',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgLowOnWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
          Text('สรุปการเดินทาง', style: AppTypography.label2),
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
                    'คาดว่าจะถึง',
                    '${_formatClock((liveState.etaArriveAt as DateTime).add(const Duration(minutes: _kEtaBufferMinutes)))} น.',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ราคารวม', style: AppTypography.label1),
              Text(
                '฿${liveState.fare?.toStringAsFixed(0) ?? '--'}',
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
    final method =
        (ref.watch(bookingControllerProvider).value?.paymentMethod ?? 'CASH')
            .toUpperCase();
    final isPromptPay = method == 'PROMPTPAY';
    final isCard = method == 'CARD';
    final label = isPromptPay
        ? 'พร้อมเพย์'
        : isCard
        ? 'บัตร'
        : 'เงินสด';
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
                'วิธีชำระเงิน',
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

/// A thin vertical dashed line — the pickup→dropoff connector in the location
/// card (dashed instead of a solid rule, matching the route styling).
class _DashedVerticalLine extends StatelessWidget {
  const _DashedVerticalLine({required this.height, required this.color});

  final double height;
  final Color color;

  static const double _thickness = 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: _thickness,
      child: CustomPaint(painter: _DashedLinePainter(color: color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  static const double _dashHeight = 3;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + _dashHeight).clamp(0, size.height)),
        paint,
      );
      y += _dashHeight + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}
