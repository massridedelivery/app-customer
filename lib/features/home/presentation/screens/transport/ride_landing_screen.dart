import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
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

  // "แผนที่": pick the pickup point on the map, then the dropoff point. The
  // dropoff screen's confirm continues to the vehicle-selection screen
  // (/booking), so the map button walks pickup -> dropoff -> เลือกรถ.
  Future<void> _openMapSelection() async {
    final notifier = ref.read(homeControllerProvider.notifier);
    notifier.startSelection(mode: RideSelectionMode.pickup);
    await context.push('/select-pickup');
    if (!mounted) return;
    // Bail out if the user backed out of the pickup step without confirming.
    if (ref.read(homeControllerProvider).pickupLocation == null) return;
    notifier.startSelection(mode: RideSelectionMode.dropoff);
    context.push('/select-dropoff');
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
            const SizedBox(height: 28),
            // Recent trips — driven by homeState.recentPlaces
            // (GET /api/customer/places/frequent). Hidden when empty so there's
            // no dangling header while the endpoint returns nothing.
            if (homeState.recentPlaces.isNotEmpty) ...[
              _buildRecentTrips(homeState.recentPlaces),
              const SizedBox(height: 28),
            ],
            _buildExperienceSection(),
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
    return ClipPath(
      clipper: _HeaderWaveClipper(),
      child: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.foundationRed700, AppColors.foundationRed900],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 52),
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
                    onTap: _openMapSelection,
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

              // Search bar.
              InkWell(
                onTap: () => context.push('/place-search'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
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
            ],
          ),
        ),
      ),
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

  // ---------------------------------------------------------------------------
  // "สัมผัสประสบการณ์ใหม่กับ Mass Move" — horizontal feature cards that fill out
  // the lower half of the screen.
  // ---------------------------------------------------------------------------
  Widget _buildExperienceSection() {
    final items = <({
      IconData icon,
      String title,
      String subtitle,
      List<Color> colors,
    })>[
      (
        icon: Icons.workspace_premium_rounded,
        title: 'การเดินทางระดับพรีเมียม',
        subtitle: 'รถพร้อมสิ่งอำนวยความสะดวกครบครัน',
        colors: [AppColors.foundationRed600, AppColors.foundationRed800],
      ),
      (
        icon: Icons.flight_takeoff_rounded,
        title: 'ไปสนามบิน ตรงเวลา',
        subtitle: 'จองล่วงหน้า ไม่พลาดไฟลต์',
        colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      ),
      (
        icon: Icons.verified_user_rounded,
        title: 'ปลอดภัยทุกเส้นทาง',
        subtitle: 'แชร์ตำแหน่งเรียลไทม์ + ปุ่ม SOS',
        colors: [AppColors.success, const Color(0xFF059669)],
      ),
      (
        icon: Icons.savings_rounded,
        title: 'ราคาคุ้มค่า ถูกกว่าชัวร์',
        subtitle: 'ค่าโดยสารโปร่งใส รู้ราคาก่อนเรียก',
        colors: [
          AppColors.foundationOrange500,
          AppColors.foundationOrange700,
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'สัมผัสประสบการณ์ใหม่กับ Mass Move',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _experienceCard(items[i]),
          ),
        ),
      ],
    );
  }

  Widget _experienceCard(
    ({IconData icon, String title, String subtitle, List<Color> colors}) item,
  ) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 88,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.colors,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Icon(item.icon, color: Colors.white, size: 40),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.label1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Gives the red header a soft double-wave bottom edge (see reference design).
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..lineTo(0, h - 36)
      ..quadraticBezierTo(w * 0.25, h, w * 0.52, h - 16)
      ..quadraticBezierTo(w * 0.80, h - 40, w, h - 6)
      ..lineTo(w, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
