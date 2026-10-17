import 'package:customer_app/features/profile/data/welcome_promo_store.dart';
import 'dart:async';

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/utils/auth_gate.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/booking_map_widget.dart';
import 'package:customer_app/features/ride_booking/presentation/screens/ride_coupon_screen.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/vehicle_selection_sheet.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  GoogleMapController? _mapController;
  Offset? _pickupPos;
  Offset? _dropoffPos;
  bool _isUpdatingCoords = false;
  // Set when a camera callback arrives mid-update, so we re-run once more with
  // the final camera instead of dropping the trailing onCameraIdle.
  bool _coordsDirty = false;
  // Cached so the widget tree never collapses to a bare loading Scaffold.
  // During bookingAsync.isLoading the last known state keeps all widgets mounted,
  // preventing the RenderBox-not-laid-out crash in VehicleSelectionSheet/ListView.
  BookingState _lastKnownState = const BookingState();

  // Keep the per-vehicle "drivers nearby" counts live while the user is picking
  // a vehicle: silently re-estimate every 30s (no spinner). The timer lives with
  // this screen, so it stops the moment we leave — dispatch pushReplacement's to
  // /live and back goes to the pickup/dropoff screen, both disposing this state.
  // Re-entering builds a fresh screen → fresh estimate + a fresh timer.
  Timer? _nearbyTimer;
  AppLifecycleListener? _lifecycle;
  static const _nearbyRefreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _startNearbyPolling();
    // Pause while backgrounded (no point spending calls); refresh + resume the
    // instant we return so the count is current when the user looks again.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _refreshNearbyDrivers();
        _startNearbyPolling();
      },
      onPause: () => _nearbyTimer?.cancel(),
    );
  }

  void _startNearbyPolling() {
    _nearbyTimer?.cancel();
    _nearbyTimer = Timer.periodic(
      _nearbyRefreshInterval,
      (_) => _refreshNearbyDrivers(),
    );
  }

  /// Silent re-estimate to refresh drivers-nearby. No-op unless we're still on
  /// the vehicle-selection step with a loaded estimate and no ride dispatched.
  void _refreshNearbyDrivers() {
    if (!mounted) return;
    final home = ref.read(homeControllerProvider);
    final pickup = home.pickupLocation;
    final dropoff = home.dropoffLocation;
    if (pickup == null || dropoff == null) return;
    final st = ref.read(bookingControllerProvider).value;
    if (st == null || st.estimations.isEmpty || st.activeJobId != null) return;
    ref.read(bookingControllerProvider.notifier).refreshEstimate(
          pickup,
          dropoff,
          promoCode: st.appliedPromoCode,
        );
  }

  @override
  void dispose() {
    _nearbyTimer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _updateScreenPositions() async {
    if (_mapController == null || !mounted) return;
    // Coalesce bursts of onCameraMove/onCameraIdle callbacks: if an update is
    // already running, flag it dirty so it re-runs once with the final camera
    // position rather than dropping the trailing update and leaving overlays
    // stuck at a mid-animation position.
    if (_isUpdatingCoords) {
      _coordsDirty = true;
      return;
    }
    _isUpdatingCoords = true;
    try {
      do {
        _coordsDirty = false;
        final homeState = ref.read(homeControllerProvider);
        final pickup = homeState.pickupLocation;
        final dropoff = homeState.dropoffLocation;

        // getScreenCoordinate returns PHYSICAL pixels on Android but LOGICAL
        // points on iOS. Divide by the device pixel ratio only on Android —
        // dividing on iOS shrank every coordinate ~3x, collapsing the address
        // bubbles into the top-left corner (the reported bug). Emulator testing
        // on Android never surfaced it.
        final divisor = defaultTargetPlatform == TargetPlatform.android
            ? MediaQuery.of(context).devicePixelRatio
            : 1.0;

        if (pickup != null) {
          final pickupScreen = await _mapController!.getScreenCoordinate(pickup);
          if (!mounted) return;
          setState(() {
            _pickupPos = Offset(
              pickupScreen.x.toDouble() / divisor,
              pickupScreen.y.toDouble() / divisor,
            );
          });
        }
        if (dropoff != null) {
          final dropoffScreen = await _mapController!.getScreenCoordinate(
            dropoff,
          );
          if (!mounted) return;
          setState(() {
            _dropoffPos = Offset(
              dropoffScreen.x.toDouble() / divisor,
              dropoffScreen.y.toDouble() / divisor,
            );
          });
        }
      } while (_coordsDirty && mounted);
    } catch (e) {
      debugPrint('Failed to get screen coords: $e');
    } finally {
      _isUpdatingCoords = false;
    }
  }

  /// The address bubbles for both pins plus the trip duration/distance pill,
  /// laid out together by [_MapOverlayLayoutDelegate] so the pill can steer
  /// clear of the bubbles and pins (it used to sit on the pins' midpoint
  /// regardless, covering the pickup bubble on a mostly vertical route).
  Widget _buildMapOverlays({
    required BookingState state,
    required AppLocalizations l10n,
    required String pickupAddress,
    required String dropoffAddress,
  }) {
    return Positioned.fill(
      child: CustomMultiChildLayout(
        delegate: _MapOverlayLayoutDelegate(
          pickup: _pickupPos,
          dropoff: _dropoffPos,
          safeTop: MediaQuery.of(context).padding.top,
        ),
        children: [
          if (_pickupPos != null)
            LayoutId(
              id: _MapOverlaySlot.pickup,
              child: _LocationOverlay(
                label: "1",
                labelColor: AppColors.foundationGreen500,
                address: pickupAddress,
              ),
            ),
          if (_dropoffPos != null)
            LayoutId(
              id: _MapOverlaySlot.dropoff,
              child: _LocationOverlay(
                label: "2",
                labelColor: AppColors.foundationRed600,
                address: dropoffAddress,
              ),
            ),
          // Total-trip duration + distance. Belongs to the route as a whole,
          // so it is centred between the pins when that spot is free.
          if (_pickupPos != null && _dropoffPos != null)
            LayoutId(
              id: _MapOverlaySlot.metric,
              child: _buildRouteMetricTag(state, l10n),
            ),
        ],
      ),
    );
  }

  /// The trip's total duration + distance pill. Positioned by
  /// [_MapOverlayLayoutDelegate].
  Widget _buildRouteMetricTag(BookingState state, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.semanticGrayNeutralFgHigh,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        "${(state.durationMin ?? 0).toStringAsFixed(0)} ${l10n.minutes} · ${(state.distanceKm ?? 0).toStringAsFixed(1)} ${l10n.km}",
        style: AppTypography.numericMedium4.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Re-estimates with [promoCode] (null = remove the code), keeps the
  /// selected vehicle, and tells the rider what the estimate did with it.
  Future<void> _repriceWithPromo(
    String? promoCode,
    LatLng pickup,
    LatLng dropoff,
    AppLocalizations l10n,
  ) async {
    // Keep track of selected vehicle to restore after re-estimate.
    // Do NOT pass vehicleTypeId to estimateFare — the API should
    // always return all vehicle types so the list stays complete.
    final previousVehicleId =
        ref.read(bookingControllerProvider).value?.vehicleTypeId;

    await ref.read(bookingControllerProvider.notifier).estimateFare(
      pickup,
      dropoff,
      promoCode: promoCode,
    );

    // Restore the vehicle selection the user had before re-estimate.
    if (previousVehicleId != null) {
      ref.read(bookingControllerProvider.notifier).setVehicleType(previousVehicleId);
    }

    // Tell the rider what the fare estimate actually did with the code:
    // discount 0 means it doesn't apply to this trip (min spend, used up,
    // wrong service…), so don't say "applied".
    if (!mounted) return;
    final st = ref.read(bookingControllerProvider).value;
    VehicleEstimation? est;
    for (final e in st?.estimations ?? const <VehicleEstimation>[]) {
      if (e.vehicleTypeId == st?.vehicleTypeId) est = e;
    }
    est ??= (st?.estimations.isNotEmpty ?? false) ? st!.estimations.first : null;
    final notApplied = promoCode != null && est != null && est.discount <= 0;
    // The estimate only says "฿0"; /promos/validate says why (new users only,
    // minimum spend, fully redeemed…). Fall back to the generic line.
    String? reason;
    if (notApplied) {
      reason = await ref
          .read(bookingControllerProvider.notifier)
          .promoRejectionReason(promoCode);
      if (!mounted) return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            promoCode == null
                ? l10n.couponRemoved
                : notApplied
                ? (reason != null
                      ? l10n.couponNotAppliedReason(promoCode, reason)
                      : l10n.couponNotAppliedToFare(promoCode))
                : l10n.couponApplied(promoCode),
          ),
          backgroundColor:
              notApplied ? AppColors.textSecondary : AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingControllerProvider);
    // Select only the fields this screen renders — a whole-state watch would
    // rebuild the map subtree on every unrelated HomeState change.
    final pickup = ref.watch(
      homeControllerProvider.select((s) => s.pickupLocation),
    );
    final dropoff = ref.watch(
      homeControllerProvider.select((s) => s.dropoffLocation),
    );
    final pickupAddress = ref.watch(
      homeControllerProvider.select((s) => s.pickupAddress),
    );
    final dropoffAddress = ref.watch(
      homeControllerProvider.select((s) => s.dropoffAddress),
    );
    final l10n = AppLocalizations.of(context)!;

    // Update the cache whenever new data arrives.
    // We intentionally do NOT return a different Scaffold for loading/error:
    // swapping widget trees destroys VehicleSelectionSheet + ListView, leaving
    // their RenderBoxes in a 'not laid out' state → the RenderBox crash.
    if (bookingAsync.hasValue) {
      _lastKnownState = bookingAsync.value!;
    }
    final bookingState = _lastKnownState; // always non-null

    // Auto-estimate fare on load (only once if state is empty)
    if (pickup != null && dropoff != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!bookingAsync.isLoading &&
            !bookingAsync.hasError &&
            _lastKnownState.distanceKm == null) {
          // A referred newcomer's welcome code (e.g. FRIEND50) is applied on
          // their first ride; they can still remove it (✕ on the coupon).
          final welcome = _lastKnownState.appliedPromoCode == null
              ? ref.read(welcomePromoStoreProvider).code
              : null;
          ref
              .read(bookingControllerProvider.notifier)
              .estimateFare(pickup, dropoff, promoCode: welcome);
        }
      });
    }

    // Listen for active job to navigate
    ref.listen(bookingControllerProvider, (previous, next) {
      next.whenData((state) {
        if (state.activeJobId != null &&
            state.activeJobId != previous?.value?.activeJobId) {
          // Pay-at-destination (dev14): PROMPTPAY is no longer collected before
          // matching. Every ride goes straight to live tracking; the QR is
          // surfaced at the destination (LiveRideController.awaitingPromptPay)
          // when the driver opens the collection intent.
          context.pushReplacement('/live/${state.activeJobId}');
        }
      });
    });

    // Listen for errors and show SnackBar (error is shown without replacing UI)
    ref.listen(bookingControllerProvider, (previous, next) {
      if (next is AsyncError) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    apiErrorMessage(next.error),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.foundationRed600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Map Background
          BookingMapWidget(
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 350), () {
                _updateScreenPositions();
              });
            },
            onCameraMove: (position) => _updateScreenPositions(),
            onCameraIdle: () => _updateScreenPositions(),
          ),

          // Address bubbles + trip duration/distance pill.
          if (pickup != null && dropoff != null)
            _buildMapOverlays(
              state: bookingState,
              l10n: l10n,
              pickupAddress: pickupAddress ?? l10n.currentLocation,
              dropoffAddress: dropoffAddress ?? l10n.dropoffPoint,
            ),

          // Top Back Arrow Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: InkWell(
              // Pop back through the stack (place-search → landing → home) so
              // the user can always reach the home screen. Using context.go
              // here reset the stack and trapped later back presses.
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/main');
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ),

          // Loading overlay
          if (bookingAsync.isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: MassLoadingM(size: 72)),
              ),
            ),

          // Bottom Vehicle Selection Sheet — draggable, snapping to ~1 row,
          // ~3 rows and almost-full-screen.
          DraggableScrollableSheet(
            initialChildSize: 0.48,
            minChildSize: 0.32,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.32, 0.48, 0.92],
            builder: (context, scrollController) => VehicleSelectionSheet(
              scrollController: scrollController,
              estimations: bookingState.estimations,
              isMissingLocation: pickup == null || dropoff == null,
              onPickLocation: () => context.pushReplacement('/place-search'),
              onRetryEstimate: pickup == null || dropoff == null
                  ? null
                  : () => ref
                        .read(bookingControllerProvider.notifier)
                        .estimateFare(pickup, dropoff),
              onVehicleSelected: (id) {
                ref
                    .read(bookingControllerProvider.notifier)
                    .setVehicleType(id);
              },
              onPromoTap: () async {
                // Await the result: non-empty string = promo applied, '' = cancelled, null = dismissed
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RideCouponScreen(),
                  ),
                );

                // Only re-estimate if the user explicitly applied or cancelled a promo.
                // result == null means they just pressed back without action.
                if (result != null && pickup != null && dropoff != null) {
                  await _repriceWithPromo(
                    result.isEmpty ? null : result,
                    pickup,
                    dropoff,
                    l10n,
                  );
                }
              },
              // Drop the code straight from the sheet (✕ on the coupon button /
              // "เอาโค้ดออก" on a code that doesn't apply) — no coupon screen.
              onPromoRemove: pickup == null || dropoff == null
                  ? null
                  : () => _repriceWithPromo(null, pickup, dropoff, l10n),
              onRequest: () async {
                // Tell the user instead of silently ignoring the tap — e.g.
                // location is off and no pickup was chosen manually.
                if (pickup == null || dropoff == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.selectPickupFirst)),
                  );
                  return;
                }
                // Booking is account-based — a guest must log in first.
                if (!ensureLoggedIn(context, ref)) return;

                await ref
                    .read(bookingControllerProvider.notifier)
                    .dispatchRide(
                      pickup: pickup,
                      dropoff: dropoff,
                      // Pickup coordinates are set here; a null address only
                      // means reverse geocoding failed, i.e. the GPS position.
                      pickupAddress:
                          pickupAddress ?? l10n.currentLocation,
                      dropoffAddress:
                          dropoffAddress ?? l10n.rideDropoffUnspecified,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _MapOverlaySlot { pickup, dropoff, metric }

/// Lays out the pickup/dropoff address bubbles and the trip metric pill over
/// the booking map, from the pins' screen positions.
///
/// Each bubble sits above its marker, flipping below when there isn't room
/// under the status bar, and is clamped (using its *measured* size) so neither
/// edge is clipped. The pill then goes to the first candidate spot — the
/// pins' midpoint, then nudged sideways / up / down — that overlaps neither
/// bubble nor either pin, falling back to the midpoint.
class _MapOverlayLayoutDelegate extends MultiChildLayoutDelegate {
  final Offset? pickup;
  final Offset? dropoff;
  final double safeTop;

  // Gap between the marker and the bubble on each flip side, and the minimum
  // breathing room to keep from any screen edge.
  static const double _gapAbove = 45.0;
  static const double _gapBelow = 12.0;
  static const double _margin = 12.0;

  // On-screen pin footprint (MapMarkerUtils draws 44px pins whose tip is the
  // marker's coordinate) and the clearance the pill keeps from everything.
  static const double _pinSize = 44.0;
  static const double _clearance = 6.0;

  _MapOverlayLayoutDelegate({
    required this.pickup,
    required this.dropoff,
    required this.safeTop,
  });

  @override
  void performLayout(Size size) {
    final occupied = <Rect>[];

    for (final (slot, anchor) in [
      (_MapOverlaySlot.pickup, pickup),
      (_MapOverlaySlot.dropoff, dropoff),
    ]) {
      if (anchor == null || !hasChild(slot)) continue;
      // Keep the 60%-of-width cap so long addresses wrap instead of
      // stretching across the whole map.
      final bubble = layoutChild(
        slot,
        BoxConstraints(maxWidth: size.width * 0.6, maxHeight: size.height),
      );
      final offset = _bubbleOffset(anchor, bubble, size);
      positionChild(slot, offset);
      occupied
        ..add(offset & bubble)
        ..add(
          Rect.fromLTWH(
            anchor.dx - _pinSize / 2,
            anchor.dy - _pinSize,
            _pinSize,
            _pinSize,
          ),
        );
    }

    if (!hasChild(_MapOverlaySlot.metric)) return;
    final pill = layoutChild(
      _MapOverlaySlot.metric,
      BoxConstraints.loose(size),
    );
    if (pickup == null || dropoff == null) {
      positionChild(_MapOverlaySlot.metric, Offset.zero);
      return;
    }

    final mid = (pickup! + dropoff!) / 2;
    final stepY = pill.height + _clearance * 2;
    final stepX = pill.width / 2 + _pinSize / 2 + _clearance;
    // Sideways first: those stay level with the midpoint, which fit-to-bounds
    // keeps above the bottom sheet; a downward nudge could slide under it.
    final candidates = [
      mid,
      mid.translate(stepX, 0),
      mid.translate(-stepX, 0),
      mid.translate(0, -stepY),
      mid.translate(0, stepY),
      mid.translate(0, -stepY * 2),
      mid.translate(0, stepY * 2),
    ].map((centre) => _clampPill(centre, pill, size)).toList();

    final placed = candidates.firstWhere(
      (rect) => !occupied.any((o) => o.overlaps(rect.inflate(_clearance))),
      orElse: () => candidates.first,
    );
    positionChild(_MapOverlaySlot.metric, placed.topLeft);
  }

  Offset _bubbleOffset(Offset anchor, Size bubble, Size size) {
    final placeAbove = anchor.dy - _gapAbove - bubble.height > safeTop + 8;
    final top = placeAbove
        ? anchor.dy - _gapAbove - bubble.height
        : anchor.dy + _gapBelow;
    final left = anchor.dx - bubble.width / 2;
    return Offset(
      left.clamp(_margin, size.width - bubble.width - _margin),
      top.clamp(safeTop + 8, size.height - bubble.height - _margin),
    );
  }

  /// The pill's rect centred on [centre], clamped fully on-screen and below
  /// the status bar.
  Rect _clampPill(Offset centre, Size pill, Size size) {
    final left = (centre.dx - pill.width / 2).clamp(
      _margin,
      size.width - pill.width - _margin,
    );
    final top = (centre.dy - pill.height / 2).clamp(
      safeTop + _margin,
      size.height - pill.height - _margin,
    );
    return Offset(left, top) & pill;
  }

  @override
  bool shouldRelayout(_MapOverlayLayoutDelegate oldDelegate) =>
      pickup != oldDelegate.pickup ||
      dropoff != oldDelegate.dropoff ||
      safeTop != oldDelegate.safeTop;
}

class _LocationOverlay extends StatelessWidget {
  final String label;
  final Color labelColor;
  final String address;

  const _LocationOverlay({
    required this.label,
    required this.labelColor,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: labelColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              label,
              style: AppTypography.numericMedium4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption5.copyWith(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
