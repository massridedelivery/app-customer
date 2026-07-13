import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/BookingMapWidget.dart';
import 'package:customer_app/features/ride_booking/presentation/screens/ride_coupon_screen.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/vehicle_selection_sheet.dart';
import 'package:customer_app/l10n/app_localizations.dart';
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
  // Cached so the widget tree never collapses to a bare loading Scaffold.
  // During bookingAsync.isLoading the last known state keeps all widgets mounted,
  // preventing the RenderBox-not-laid-out crash in VehicleSelectionSheet/ListView.
  BookingState _lastKnownState = const BookingState();

  Future<void> _updateScreenPositions() async {
    if (_mapController == null || _isUpdatingCoords || !mounted) return;
    _isUpdatingCoords = true;
    try {
      final homeState = ref.read(homeControllerProvider);
      final pickup = homeState.pickupLocation;
      final dropoff = homeState.dropoffLocation;

      final pixelRatio = MediaQuery.of(context).devicePixelRatio;

      if (pickup != null) {
        final pickupScreen = await _mapController!.getScreenCoordinate(pickup);
        if (mounted) {
          setState(() {
            _pickupPos = Offset(
              pickupScreen.x.toDouble() / pixelRatio,
              pickupScreen.y.toDouble() / pixelRatio,
            );
          });
        }
      }
      if (dropoff != null) {
        final dropoffScreen = await _mapController!.getScreenCoordinate(
          dropoff,
        );
        if (mounted) {
          setState(() {
            _dropoffPos = Offset(
              dropoffScreen.x.toDouble() / pixelRatio,
              dropoffScreen.y.toDouble() / pixelRatio,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to get screen coords: $e');
    } finally {
      _isUpdatingCoords = false;
    }
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
          ref
              .read(bookingControllerProvider.notifier)
              .estimateFare(pickup, dropoff);
        }
      });
    }

    // Listen for active job to navigate
    ref.listen(bookingControllerProvider, (previous, next) {
      next.whenData((state) {
        if (state.activeJobId != null &&
            state.activeJobId != previous?.value?.activeJobId) {
          // PromptPay must be paid before matching: route to the QR screen,
          // which proceeds to /live on PAID. Cash goes straight to tracking.
          if (state.paymentMethod == 'PROMPTPAY') {
            context.push(
              '/payment/promptpay',
              extra: {'jobId': state.activeJobId},
            );
          } else {
            context.pushReplacement('/live/${state.activeJobId}');
          }
        }
      });
    });

    // Listen for errors and show SnackBar (error is shown without replacing UI)
    ref.listen(bookingControllerProvider, (previous, next) {
      if (next is AsyncError && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.foundationRed600,
            behavior: SnackBarBehavior.floating,
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

          // Dynamic Location Overlays
          if (pickup != null && dropoff != null) ...[
            if (_pickupPos != null)
              Positioned(
                left: _pickupPos!.dx,
                top: _pickupPos!.dy - 45, // Position above pickup marker
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1.0),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    child: _LocationOverlay(
                      label: "1",
                      labelColor: AppColors.foundationGreen500,
                      address:
                          pickupAddress ?? l10n.currentLocation,
                    ),
                  ),
                ),
              ),
            if (_dropoffPos != null) ...[
              Positioned(
                left: _dropoffPos!.dx,
                top: _dropoffPos!.dy - 45, // Position above dropoff marker
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1.0),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    child: _LocationOverlay(
                      label: "2",
                      labelColor: AppColors.foundationRed600,
                      address: dropoffAddress ?? l10n.dropoffPoint,
                    ),
                  ),
                ),
              ),
              // Duration & Distance tag attached to dropoff marker
              Positioned(
                left: _dropoffPos!.dx + 16,
                top: _dropoffPos!.dy - 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    "${(bookingState.durationMin ?? 0).toStringAsFixed(0)} ${l10n.minutes} · ${(bookingState.distanceKm ?? 0).toStringAsFixed(1)} ${l10n.km}",
                    style: AppTypography.numericMedium4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],

          // Top Back Arrow Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: InkWell(
              onTap: () => context.pop(),
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
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            ),

          // Bottom Vehicle Selection Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: VehicleSelectionSheet(
              estimations: bookingState.estimations,
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
                  final promoCode = result.isEmpty ? null : result;
                  // Keep track of selected vehicle to restore after re-estimate.
                  // Do NOT pass vehicleTypeId to estimateFare — the API should
                  // always return all vehicle types so the list stays complete.
                  final previousVehicleId =
                      ref.read(bookingControllerProvider).value?.vehicleTypeId;

                  // Show snackbar feedback
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          promoCode != null
                              ? 'ใช้คูปอง "$promoCode" สำเร็จ'
                              : 'ยกเลิกคูปองเรียบร้อยแล้ว',
                        ),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }

                  await ref.read(bookingControllerProvider.notifier).estimateFare(
                    pickup,
                    dropoff,
                    promoCode: promoCode,
                    // vehicleTypeId intentionally omitted — let API return all types.
                  );

                  // Restore the vehicle selection the user had before re-estimate.
                  if (previousVehicleId != null) {
                    ref
                        .read(bookingControllerProvider.notifier)
                        .setVehicleType(previousVehicleId);
                  }
                }
              },
              onRequest: () async {
                if (pickup == null || dropoff == null) return;

                await ref
                    .read(bookingControllerProvider.notifier)
                    .dispatchRide(
                      pickup: pickup,
                      dropoff: dropoff,
                      pickupAddress:
                          pickupAddress ?? 'Unknown Pickup',
                      dropoffAddress:
                          dropoffAddress ?? 'Unknown Dropoff',
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
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
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
