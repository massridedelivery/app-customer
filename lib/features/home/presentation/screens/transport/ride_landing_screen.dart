import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideLandingScreen extends ConsumerStatefulWidget {
  const RideLandingScreen({super.key});

  @override
  ConsumerState<RideLandingScreen> createState() => _RideLandingScreenState();
}

class _RideLandingScreenState extends ConsumerState<RideLandingScreen> {
  // Recent list shows the first few by default; "see more" reveals the rest.
  static const _recentCollapsedCount = 3;
  bool _recentExpanded = false;

  void _openDropoff(Place place) {
    ref
        .read(homeControllerProvider.notifier)
        .setDropoffLocation(LatLng(place.lat, place.lng), place.name);
    context.push('/booking');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final homeState = ref.watch(homeControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.foundationGrayscale75,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, l10n),
            const SizedBox(height: 20),
            _buildQuickActions(context, l10n, homeState.savedPlaces),
            const SizedBox(height: 24),
            _buildPromoBanner(context),
            const SizedBox(height: 28),
            // Recent trips — driven by homeState.recentPlaces
            // (GET /api/customer/places/recent). Hidden when empty so there's no
            // dangling header while the endpoint returns nothing.
            if (homeState.recentPlaces.isNotEmpty)
              _buildRecentTrips(homeState.recentPlaces),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header: brand-red rounded card with title, search bar, schedule button and
  // a promo strip (Grab-style layout, MassMove brand colours).
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.foundationRed700, AppColors.foundationRed900],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: back button + map pill.
              Row(
                children: [
                  _circleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => context.push('/place-search'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'แผนที่',
                            style: AppTypography.label2.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Mass Move',
                style: AppTypography.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.newPriceSure,
                style: AppTypography.caption3.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Text(
                l10n.gelPromo,
                style: AppTypography.caption3.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 20),

              // Search bar + schedule button.
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/place-search'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            AppIcons.asset(
                              AppAssets.icLocationPinLine,
                              color: AppColors.primary,
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.whereTo,
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => context.push('/place-search'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ภายหลัง',
                            style: AppTypography.label2.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Promo strip.
              _buildGroupRidePromo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupRidePromo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Ride',
                  style: AppTypography.label1.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'รวมแก๊งครบ 4 คน ลดเพิ่มสูงสุด 20%',
                  style: AppTypography.caption4.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Quick actions: saved places + add address.
  // ---------------------------------------------------------------------------
  Widget _buildQuickActions(
    BuildContext context,
    AppLocalizations l10n,
    List<Place> savedPlaces,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ...savedPlaces.take(2).map(
            (place) => Expanded(
              child: _quickActionChip(
                label: place.name,
                icon: AppAssets.icLocationPinLine,
                onTap: () {
                  ref
                      .read(homeControllerProvider.notifier)
                      .setDropoffLocation(
                        LatLng(place.lat, place.lng),
                        place.name,
                      );
                  context.push('/booking');
                },
              ),
            ),
          ),
          Expanded(
            child: _quickActionChip(
              label: l10n.addAddress,
              icon: AppAssets.icPlus,
              muted: true,
              onTap: () async {
                await context.push('/add-address');
                if (!mounted) return;
                ref.read(homeControllerProvider.notifier).refreshSavedPlaces();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionChip({
    required String label,
    required String icon,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: muted ? AppColors.foundationGrayscale100 : AppColors.softRedBg,
                  shape: BoxShape.circle,
                ),
                child: AppIcons.asset(
                  icon,
                  color: muted
                      ? AppColors.foundationGrayscale600
                      : AppColors.primary,
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: AppTypography.label2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Promo banner (keeps the layout from filling out even with no recent trips).
  // ---------------------------------------------------------------------------
  Widget _buildPromoBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => context.push('/place-search'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.softRedBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.foundationRed200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'มีแผนเดินทางล่วงหน้า?',
                      style: AppTypography.label1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'จองรถล่วงหน้าไว้ ไม่ต้องรีบ ไม่พลาดเวลา',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'จองล่วงหน้า',
                        style: AppTypography.label2.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recent trips.
  // ---------------------------------------------------------------------------
  Widget _buildRecentTrips(List<Place> places) {
    final visible = _recentExpanded
        ? places
        : places.take(_recentCollapsedCount).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เดินทางล่าสุด',
            style: AppTypography.heading5.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 60, endIndent: 16),
                  _buildRecentItem(visible[i]),
                ],
              ],
            ),
          ),
          if (places.length > _recentCollapsedCount) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => _recentExpanded = !_recentExpanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.seeMore,
                      style: AppTypography.label1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _recentExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentItem(Place place) {
    final hasAddress = place.address?.isNotEmpty == true;
    return InkWell(
      onTap: () => _openDropoff(place),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.foundationGrayscale100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                color: AppColors.foundationGrayscale700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: AppTypography.label1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasAddress) ...[
                    const SizedBox(height: 2),
                    Text(
                      place.address!,
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.foundationGrayscale500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
