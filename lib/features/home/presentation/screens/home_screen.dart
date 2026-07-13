import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  bool _hasAnimatedToLocation = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Select only what this screen renders — a whole-state watch would
    // rebuild the GoogleMap on every unrelated HomeState change.
    final selectionMode = ref.watch(
      homeControllerProvider.select((s) => s.selectionMode),
    );
    final currentLocation = ref.watch(
      homeControllerProvider.select((s) => s.currentLocation),
    );
    final isSelecting = selectionMode != RideSelectionMode.none;

    // Listen for location updates to animate camera ONCE at startup
    ref.listen(homeControllerProvider.select((s) => s.currentLocation), (
      previous,
      next,
    ) {
      if (next != null && !_hasAnimatedToLocation && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(next, 15.0));
        setState(() {
          _hasAnimatedToLocation = true;
        });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isSelecting) {
          ref.read(homeControllerProvider.notifier).cancelSelection();
        } else {
          context.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // 1. Map Layer
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                    currentLocation ??
                    const LatLng(13.7563, 100.5018),
                zoom: 15.0,
              ),
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              // normal loads noticeably faster than terrain and suits
              // ride-hailing UI better.
              mapType: MapType.normal,
              onCameraMove: (position) {
                ref
                    .read(homeControllerProvider.notifier)
                    .onCameraMove(position);
              },
              onCameraIdle: () {
                ref.read(homeControllerProvider.notifier).onCameraIdle();
              },
              markers: const {},
            ),

            // 2. Back Button (Top Left)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  if (isSelecting) {
                    ref.read(homeControllerProvider.notifier).cancelSelection();
                  } else {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(
                        '/main',
                      ); // Fallback if entered directly or stack cleared
                    }
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.semanticGrayNeutralBgWhite,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.foundationAlphaBlack100,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            ),

            // 3. Location Center Button (Bottom Right)
            Positioned(
              right: 16,
              bottom: isSelecting
                  ? 100 // Above apply button
                  : MediaQuery.of(context).size.height * 0.4 +
                        16, // Above home sheet
              child: FloatingActionButton(
                heroTag: 'center_loc',
                mini: true,
                backgroundColor: AppColors.semanticGrayNeutralBgWhite,
                foregroundColor: AppColors.semanticGrayNeutralFgHigh,
                onPressed: () {
                  if (currentLocation != null && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(currentLocation, 15.0),
                    );
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ),

            // 4. Center Pin Marker (Only during selection)
            if (isSelecting)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 30,
                  ), // Adjust for pin tip
                  child: AppIcons.asset(
                    AppAssets.icLocationFill,
                    width: 40,
                    height: 40,
                    color: selectionMode == RideSelectionMode.dropoff
                        ? AppColors.foundationOrange700
                        : AppColors.foundationGreen500,
                  ),
                ),
              ),

            // 4. Overlay Views (Landing or Selection)
            // Positioned.fill(
            //   child: AnimatedSwitcher(
            //     duration: const Duration(milliseconds: 300),
            //     child: isSelecting
            //         ? const RideSelectionView()
            //         : const HomeLandingView(),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
