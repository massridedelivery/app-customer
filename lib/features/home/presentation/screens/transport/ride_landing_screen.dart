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

class RideLandingScreen extends ConsumerWidget {
  const RideLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.semanticGrayNeutralFgWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors
                        .semanticGrayNeutralFgWhite, // Light mint background
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mass Move',
                          style: AppTypography.heading2.copyWith(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.newPriceSure,
                          style: AppTypography.caption2,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.gelPromo,
                              style: AppTypography.caption2,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 2. Search Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => context.push('/place-search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: AppIcons.asset(
                          AppAssets.icLocationPinLine,
                          color: AppColors.white,
                          width: 20,
                          height: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        AppLocalizations.of(context)!.whereToToday,
                        style: AppTypography.caption3.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 3. Saved Places Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ...homeState.savedPlaces
                      .take(2)
                      .map(
                        (place) => InkWell(
                          onTap: () {
                            ref
                                .read(homeControllerProvider.notifier)
                                .setDropoffLocation(
                                  LatLng(place.lat, place.lng),
                                  place.name,
                                );
                            context.push('/booking');
                          },
                          child: _buildSavedPlaceItem(
                            place.name,
                            place.address ?? '',
                            AppAssets.icLocationPinLine,
                          ),
                        ),
                      ),
                  InkWell(
                    onTap: () {
                      ref
                          .read(homeControllerProvider.notifier)
                          .startSelection(mode: RideSelectionMode.savePlace);
                      context.push('/place-search');
                    },
                    child: _buildSavedPlaceItem(
                      AppLocalizations.of(context)!.addAddress,
                      ' ',
                      AppAssets.icPlus,
                      isAction: false,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 4. Recent List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.recentUsage,
                    style: AppTypography.heading5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentItem(
                    'แขวงจตุจักร เขตจตุจักร กรุงเทพมหานคร 10900 ประเทศไทย',
                    Icons.history,
                  ),
                  const Divider(height: 32),
                  _buildRecentItem(
                    '42, Verve Rama 5, อำเภอเมืองนนทบุรี, นนทบุรี, 11000, ประเทศไทย',
                    Icons.history,
                  ),
                  const Divider(height: 32),
                  _buildRecentItem(
                    'แขวงอนุสาวรีย์ เขตบางเขน กรุงเทพมหานคร 10220 ประเทศไทย',
                    Icons.history,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: Text(
                        AppLocalizations.of(context)!.seeMore,
                        style: AppTypography.label1.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      label: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPlaceItem(
    String title,
    String subtitle,
    String icon, {
    bool isAction = false,
  }) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: AppIcons.asset(
              icon,
              color: isAction ? Colors.grey : AppColors.white,
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.label2,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: AppTypography.caption4.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(String address, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            address,
            style: AppTypography.body1.copyWith(color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
