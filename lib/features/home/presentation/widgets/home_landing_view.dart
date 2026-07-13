import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeLandingView extends ConsumerStatefulWidget {
  const HomeLandingView({super.key});

  @override
  ConsumerState<HomeLandingView> createState() => _HomeLandingViewState();
}

class _HomeLandingViewState extends ConsumerState<HomeLandingView> {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final homeState = ref.watch(homeControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.40,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.35, 0.40, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.semanticGrayNeutralBgWhite,
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
              const SizedBox(height: 12),
              // Grabber
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Input Forms Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Pickup Row
                      InkWell(
                        onTap: () {
                          ref
                              .read(homeControllerProvider.notifier)
                              .startSelection(mode: RideSelectionMode.pickup);
                        },
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 24,
                              child: Center(
                                child: Icon(
                                  Icons.radio_button_checked,
                                  color: AppColors.foundationGreen500,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.pickupPoint,
                                    style: AppTypography.caption5.copyWith(
                                      color: AppColors
                                          .semanticGrayNeutralFgLowOnWhite,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.currentLocation,
                                    style: AppTypography.caption4.copyWith(
                                      color:
                                          AppColors.semanticGrayNeutralFgHigh,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider with dashed line visual
                      Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _Dot(),
                                  SizedBox(height: 4),
                                  _Dot(),
                                  SizedBox(height: 4),
                                  _Dot(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[200],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      // Drop-off Row
                      InkWell(
                        onTap: () {
                          ref
                              .read(homeControllerProvider.notifier)
                              .startSelection(mode: RideSelectionMode.dropoff);
                        },
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 24,
                              child: Center(
                                child: Icon(
                                  Icons.radio_button_checked,
                                  color: AppColors.foundationOrange600,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.dropoffPoint,
                                    style: AppTypography.support1.copyWith(
                                      color: AppColors
                                          .semanticGrayNeutralFgLowOnWhite,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.whereToGoHint,
                                    style: AppTypography.caption4.copyWith(
                                      color:
                                          AppColors.semanticGrayNeutralFgHigh,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.foundationOrange700,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.map_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: bottomPadding + 80,
                  ),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.recent,
                          style: AppTypography.label3.copyWith(
                            color: AppColors.semanticGrayNeutralFgLowOnWhite,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.foundationGreen500,
                          onPressed: () {
                            ref
                                .read(homeControllerProvider.notifier)
                                .startSelection(
                                  mode: RideSelectionMode.savePlace,
                                );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (homeState.savedPlaces.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          AppLocalizations.of(context)!.noSavedPlaces,
                          style: AppTypography.body3.copyWith(
                            color: AppColors.semanticGrayNeutralFgLowOnWhite,
                          ),
                        ),
                      ),
                    ...homeState.savedPlaces.map((place) {
                      return _buildPopularPlace(
                        place.name,
                        place.isDefault == true,
                        onTap: () {
                          final notifier = ref.read(
                            homeControllerProvider.notifier,
                          );
                          if (homeState.currentLocation != null) {
                            notifier.setPickupLocation(
                              homeState.currentLocation!,
                              homeState.pickupAddress ?? 'ตำแหน่งปัจจุบัน',
                            );
                            notifier.setDropoffLocation(
                              LatLng(place.lat, place.lng),
                              place.name,
                            );
                            context.push('/booking');
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopularPlace(
    String title,
    bool isStarred, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            AppIcons.asset(
              AppAssets.icLocationFill,
              width: 24,
              height: 24,
              color: AppColors.foundationOrange600,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
            ),
            Icon(
              isStarred ? Icons.star : Icons.star_border,
              color: isStarred ? Colors.amber : Colors.grey[300],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.foundationGrayscale300,
        shape: BoxShape.circle,
      ),
    );
  }
}
