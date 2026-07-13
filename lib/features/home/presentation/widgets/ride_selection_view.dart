import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RideSelectionView extends ConsumerWidget {
  final bool isFromAddAddress;
  const RideSelectionView({super.key, this.isFromAddAddress = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final isPickup = homeState.selectionMode == RideSelectionMode.pickup;
    final isSavePlace = homeState.selectionMode == RideSelectionMode.savePlace;
    final l10n = AppLocalizations.of(context)!;

    final currentAddress =
        homeState.tempAddress ??
        (isPickup
            ? homeState.pickupAddress
            : isSavePlace
            ? homeState.dropoffAddress
            : homeState.selectionMode == RideSelectionMode.food
            ? homeState.foodAddress
            : homeState.dropoffAddress) ??
        l10n.movingMap;

    return Stack(
      children: [
        // 1. Top Search Pill (Redesign based on pic-4)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            children: [
              // Circular Back Button
              Container(
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
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    ref.read(homeControllerProvider.notifier).cancelSelection();
                    context.pop();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Floating Search Bar
              // Expanded(
              //   child: Container(
              //     height: 52,
              //     padding: const EdgeInsets.symmetric(horizontal: 16),
              //     decoration: BoxDecoration(
              //       color: Colors.white,
              //       borderRadius: BorderRadius.circular(30),
              //       boxShadow: const [
              //         BoxShadow(
              //           color: Colors.black12,
              //           blurRadius: 8,
              //           offset: Offset(0, 2),
              //         ),
              //       ],
              //     ),
              //     child: Row(
              //       children: [
              //         Icon(
              //           Icons.circle,
              //           size: 14,
              //           color: isPickup
              //               ? AppColors.primary
              //               : AppColors.foundationRed600,
              //         ),
              //         const SizedBox(width: 12),
              //         Expanded(
              //           child: Text(
              //             isPickup ? 'รับที่ไหน?' : 'ไปที่ไหน?',
              //             style: AppTypography.body1.copyWith(
              //               color: Colors.grey.shade600,
              //             ),
              //           ),
              //         ),
              //         Icon(
              //           Icons.camera_alt_outlined,
              //           color: Colors.grey.shade600,
              //           size: 20,
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),

        // 2. Bottom Panel (Redesign based on pic-4)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Address Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFromAddAddress
                                  ? 'เลือกที่อยู่'
                                  : isSavePlace
                                  ? AppLocalizations.of(
                                      context,
                                    )!.saveThisLocation
                                  : isPickup
                                  ? 'เลือกจุดรับนี้'
                                  : homeState.selectionMode ==
                                        RideSelectionMode.food
                                  ? 'เลือกจุดส่งอาหารนี้'
                                  : 'เลือกจุดหมายปลายทางนี้',
                              style: AppTypography.heading4.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentAddress,
                              style: AppTypography.caption4.copyWith(
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Main Action Button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final notifier = ref.read(
                          homeControllerProvider.notifier,
                        );
                        if (homeState.selectionMode ==
                            RideSelectionMode.dropoff) {
                          notifier.confirmSelection();
                          context.push('/booking');
                        } else if (homeState.selectionMode ==
                            RideSelectionMode.savePlace) {
                          _showAddPlaceDialog(context, ref, homeState);
                        } else {
                          notifier.confirmSelection();
                          context.pop();
                        }
                      },
                       style: ElevatedButton.styleFrom(
                        backgroundColor: isFromAddAddress
                            ? AppColors.primary
                            : AppColors.foundationGreen500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'ถัดไป',
                        style: AppTypography.heading4.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddPlaceDialog(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
  ) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.saveLocationTitle,
            style: AppTypography.heading3.copyWith(
              color: AppColors.semanticGrayNeutralFgMidOnGray,
            ),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'e.g. Home, Work, Gym',
              hintStyle: AppTypography.caption4.copyWith(
                color: AppColors.semanticGrayNeutralFgLowOnGray,
              ),
              labelStyle: AppTypography.caption4.copyWith(
                color: AppColors.semanticGrayNeutralFgHigh,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnGray,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && state.mapCenter != null) {
                  ref
                      .read(homeControllerProvider.notifier)
                      .savePlace(
                        nameController.text,
                        state.mapCenter!.latitude,
                        state.mapCenter!.longitude,
                      );
                  ref.read(homeControllerProvider.notifier).cancelSelection();
                  Navigator.pop(context);
                }
              },
              child: Text(
                AppLocalizations.of(context)!.save,
                style: AppTypography.caption3.copyWith(
                  color: AppColors.foundationOrange600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
