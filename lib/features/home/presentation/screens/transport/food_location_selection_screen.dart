import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/home/presentation/widgets/ride_selection_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FoodLocationSelectionScreen extends ConsumerStatefulWidget {
  final bool isFromAddAddress;
  const FoodLocationSelectionScreen({super.key, this.isFromAddAddress = false});

  @override
  ConsumerState<FoodLocationSelectionScreen> createState() =>
      _FoodLocationSelectionScreenState();
}

class _FoodLocationSelectionScreenState
    extends ConsumerState<FoodLocationSelectionScreen> {
  GoogleMapController? _mapController;
  // Guards the one-shot recenter below so we never fight the user's panning.
  bool _centeredOnTarget = false;

  @override
  Widget build(BuildContext context) {
    // Only the initial camera target is needed — avoid whole-state watches
    // that would rebuild the GoogleMap on unrelated HomeState changes.
    final initialTarget = ref.watch(
      homeControllerProvider.select(
        (s) => s.foodLocation ?? s.currentLocation,
      ),
    );

    // GoogleMap.initialCameraPosition is only read once at creation, so when
    // GPS resolves afterwards the camera stays on the fallback. Recenter once
    // the moment the target first becomes available.
    ref.listen(
      homeControllerProvider.select((s) => s.foodLocation ?? s.currentLocation),
      (prev, next) {
        if (!_centeredOnTarget &&
            next != null &&
            prev != next &&
            _mapController != null) {
          _centeredOnTarget = true;
          _mapController!.animateCamera(CameraUpdate.newLatLng(next));
        }
      },
    );

    // Listen to selection mode changes to pop back to FoodDeliveryScreen when confirmed
    ref.listen(homeControllerProvider.select((s) => s.selectionMode), (
      prev,
      next,
    ) {
      if (prev == RideSelectionMode.food && next == RideSelectionMode.none) {
        // If we were just selecting food and now it's done, pop back.
        // We might need to pop twice if we came from Search Screen.
        // But the RideSelectionView already pops once.
        // We'll handle the double pop or specific navigation in the View or here.
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget ?? const LatLng(13.7563, 100.5018),
              zoom: 15.0,
            ),
            mapToolbarEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            onCameraMove: (position) {
              ref.read(homeControllerProvider.notifier).onCameraMove(position);
            },
            onCameraIdle: () {
              ref.read(homeControllerProvider.notifier).onCameraIdle();
            },
          ),

          // 2. Selection View Overlay
          Positioned.fill(
            child: RideSelectionView(isFromAddAddress: widget.isFromAddAddress),
          ),

          // 3. Center Pin Marker (Food - Blue/Orange theme usually, but let's use Red/Green consistency)
          // For delivery, let's use Red pin as "Destination"
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: AppIcons.asset(
                AppAssets.icLocationFill,
                width: 40,
                height: 40,
                color: AppColors.foundationRed700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
