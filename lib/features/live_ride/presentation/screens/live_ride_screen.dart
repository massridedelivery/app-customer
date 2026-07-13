import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/map_marker_providers.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/BookingMapWidget.dart'
    show decodedPolylineProvider;
import 'package:customer_app/features/live_ride/presentation/controllers/live_ride_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RideUIState { finding, confirming, pickupArrived, onTrip }

class LiveRideScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const LiveRideScreen({super.key, this.jobId});

  @override
  ConsumerState<LiveRideScreen> createState() => _LiveRideScreenState();
}

class _LiveRideScreenState extends ConsumerState<LiveRideScreen> {
  GoogleMapController? _mapController;

  bool _isRideDetailsExpanded = false;

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
    return widget.jobId?.toUpperCase() ?? 'UNKNOWN';
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveRideControllerProvider);
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
    // Cached decode of the route polyline (shared with BookingMapWidget).
    final routePoints = ref.watch(decodedPolylineProvider);
    // App-wide cached marker bitmaps (rasterised once per session).
    final pickupIcon = ref.watch(pickupMarkerProvider).value;
    final dropoffIcon = ref.watch(dropoffMarkerProvider).value;
    final hasDriver = liveState.driverId?.isNotEmpty ?? false;
    final uiState = _getUIState(liveState.jobStatus, hasDriver: hasDriver);

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
                '/rating/${next.jobId}',
                extra: next.driverProfile,
              );
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.jobStatus == 'COMPLETED'
                  ? AppLocalizations.of(context)!.rideCompleted
                  : AppLocalizations.of(context)!.rideCancelled,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    final pickup = pickupLocation ?? const LatLng(13.7563, 100.5018);
    final dropoff =
        dropoffLocation ?? const LatLng(13.7650, 100.5100);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bottom Layer: Map (Visible after finding driver)
          Positioned.fill(
            child: uiState != RideUIState.finding
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: pickup,
                      zoom: 14.0,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    padding: const EdgeInsets.only(bottom: 350, top: 40),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitMapToMarkers(pickup, dropoff);
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('pickup'),
                        position: pickup,
                        icon:
                            pickupIcon ??
                            BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen,
                            ),
                      ),
                      Marker(
                        markerId: const MarkerId('dropoff'),
                        position: dropoff,
                        icon:
                            dropoffIcon ??
                            BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                      ),
                      if (liveState.driverLocation != null)
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: liveState.driverLocation!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueOrange,
                          ), // Car
                        ),
                    },
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        // Memoized decode — this screen rebuilds every ~2s on
                        // driver-location updates; decoding inline would redo
                        // the whole route each time.
                        points: routePoints.isNotEmpty
                            ? routePoints
                            : [pickup, dropoff],
                        color: AppColors.accentRedDeep,
                        width: 4,
                      ),
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

          // Bottom Sheet Layer
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: uiState != RideUIState.finding
                  ? MediaQuery.of(context).size.height * 0.55
                  : MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Grab Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 30,
                      ),
                      child: Column(
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

                          // Dynamic Content
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
                      ),
                    ),
                  ),
                ],
              ),
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
                      context.go('/home');
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
                              AppLocalizations.of(context)!.cancelSearch,
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
                          "${liveState.vehicleType} • ${liveState.vehiclePlate}",
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
                  label: const Text('Chat'),
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
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Call'),
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
              const Icon(
                Icons.radio_button_checked,
                color: AppColors.aberGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup', style: AppTypography.label2),
                    const SizedBox(height: 4),
                    Text(
                      pickupAddress ?? 'Pickup Location',
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
              child: Container(
                height: 24,
                width: 2,
                color: Colors.grey.shade200,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcons.asset(
                AppAssets.icLocationFill,
                width: 20,
                height: 20,
                color: AppColors.foundationOrange700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Drop-off', style: AppTypography.label2),
                    const SizedBox(height: 4),
                    Text(
                      dropoffAddress ?? 'Dropoff Location',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ride Summary', style: AppTypography.label2),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRideDetailsExpanded = !_isRideDetailsExpanded;
                  });
                },
                child: Text(
                  _isRideDetailsExpanded ? 'Hide' : 'View',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.accentRedDeep,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isRideDetailsExpanded) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn(
                  AppLocalizations.of(context)!.distance,
                  '${bookingState.distanceKm?.toStringAsFixed(1) ?? '--'} ${AppLocalizations.of(context)!.km}',
                ),
                _buildStatColumn(
                  AppLocalizations.of(context)!.time,
                  '${bookingState.durationMin?.toStringAsFixed(0) ?? '--'} ${AppLocalizations.of(context)!.minutes}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Price', style: AppTypography.label1),
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
                'Payment Method',
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
                  color: AppColors.foundationGreen100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CASH',
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.foundationGreen700,
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
