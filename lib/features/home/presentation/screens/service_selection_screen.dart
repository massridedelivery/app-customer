import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/widgets/coming_soon_dialog.dart';
import 'package:customer_app/core/constants/layout.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
import 'package:customer_app/features/home/data/repositories/service_area_repository.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/active_orders/presentation/controllers/active_orders_controller.dart';
import 'package:customer_app/features/home/presentation/widgets/home_promo_banner.dart';
import 'package:customer_app/features/active_orders/presentation/widgets/active_orders_banner.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/core/widgets/app_network_image.dart';
import 'package:customer_app/core/widgets/hero_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceSelectionScreen extends ConsumerStatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  ConsumerState<ServiceSelectionScreen> createState() =>
      _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState
    extends ConsumerState<ServiceSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);
    // Service-card promo badges come from the customer's real active promos
    // (GET /api/customer/promo/list). While loading, on error, or when empty,
    // this stays an empty list so the cards simply show no badge.
    final promos = ref.watch(promoListProvider).maybeWhen(
          data: (raw) => raw
              .map(
                (e) => e is Map<String, dynamic>
                    ? e
                    : Map<String, dynamic>.from(e as Map),
              )
              .toList(),
          orElse: () => const <Map<String, dynamic>>[],
        );
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final statusPadding = MediaQuery.of(context).padding.top;
    const double heroHeight = 190; // fixed header height (no collapse)

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      // Fixed wave header (does NOT collapse/scroll away) floating over the
      // scrolling content — same flow as the messenger screen. The content
      // panel tucks 6px up under the wave.
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              // Content scrolls UNDER the fixed header, so push the spinner down
              // below the wave instead of letting it hide behind the red header.
              edgeOffset: heroHeight - 24,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Reserve the header's height so content starts below it, then
                  // scrolls up underneath the fixed wave.
                  const SizedBox(height: heroHeight),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.semanticGrayNeutralBgWhite,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Padding(
                        // Reserve the floating bottom nav so the last content clears it.
                        padding: EdgeInsets.only(
                          top: 2,
                          bottom: bottomPadding + kFloatingNavReserve,
                        ),
                        child: Column(
                          children: [
                            ActiveOrdersBanner(),
                            // Nudge the service grid up toward the search bar.
                            Transform.translate(
                              offset: const Offset(0, -4),
                              child: _buildServiceGrid(context, promos),
                            ),
                            // Real promotions — hides itself when there are none —
                            // sits tight under the grid (no extra gap).
                            const HomePromoBanner(),
                            // Latest articles — the gap above it is owned by the
                            // promo banner (collapses when there are no promos).
                            _buildArticlesSection(context),
                            // Hardcoded promo/restaurant sections with fake ids —
                            // see FeatureFlags.foodHomePromoSections. Hidden until
                            // wired to the discovery feed.
                            if (FeatureFlags.foodHomePromoSections) ...[
                              _buildPromoBanner(context),
                              const SizedBox(height: 20),
                              _buildSectionHeader(
                                context,
                                title: 'เมนูลด 60%',
                                emoji: '🔥',
                              ),
                              _buildHorizontalFoodList(context),
                              const SizedBox(height: 20),
                              _buildPromoCodeCard(context),
                              const SizedBox(height: 20),
                              _buildSectionHeader(context, title: 'ร้านยอดนิยม'),
                              _buildHorizontalRestaurantList(context),
                            ],
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
          // The fixed header itself — constant full (expanded) state, t = 1.0.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipPath(
                  clipper: SShapeClipper(progress: 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accentRedDeep, AppColors.primary],
                      ),
                    ),
                    // Faint delivery-icon texture, clipped to the S-shape.
                    child: const Stack(children: [HeroPatternOverlay()]),
                  ),
                ),
                _buildHeaderContent(context, homeState, 1.0, statusPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pull-to-refresh: reload the live home content — saved/default places,
  /// active orders and promotions. Articles are static so they're left as-is.
  Future<void> _handleRefresh() async {
    await Future.wait([
      ref.read(homeControllerProvider.notifier).refreshSavedPlaces(),
      ref.read(activeOrdersControllerProvider.notifier).refresh(),
      ref.refresh(promoListProvider.future),
    ]);
  }

  Widget _buildHeaderContent(
    BuildContext context,
    HomeState homeState,
    double t,
    double statusPadding,
  ) {
    // t = 1.0 (expanded), t = 0.0 (collapsed)
    final double topNavOpacity = (t - 0.6).clamp(0.0, 1.0) / 0.4;

    // Calculate vertical centering for search bar when collapsed
    // Collapsed height is 56 (excluding statusPadding)
    // Search bar height is 48
    // Center offset = (56 - 48) / 2 = 4
    final double searchBarTopCollapsed = statusPadding + 4;
    final double searchBarTopExpanded = statusPadding + 80;
    final double currentSearchBarTop =
        searchBarTopCollapsed +
        (t * (searchBarTopExpanded - searchBarTopCollapsed) - 20);

    return Stack(
      children: [
        // Expanded Elements (Top Nav) - Hides when scrolling up
        Positioned(
          top: statusPadding + 10,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: topNavOpacity,
            child: _buildTopNav(context, homeState),
          ),
        ),

        // Search Bar Area - Moves to center vertically when collapsed
        Positioned(
          top: currentSearchBarTop,
          left: 16,
          right: 16,
          child: _buildSearchBar(t),
        ),
      ],
    );
  }

  Widget _buildTopNav(BuildContext context, HomeState homeState) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/food-place-search'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                AppIcons.asset(
                  AppAssets.icLocationFill,
                  color: AppColors.semanticGrayNeutralBgWhite,
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เลือกสถานที่จัดส่ง',
                        style: AppTypography.caption4.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              homeState.foodAddress ?? 'โปรดเลือกสถานที่',
                              style: AppTypography.label2.copyWith(
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Heart → the customer's saved (favorited) restaurants.
        _buildCircularButton(
          Icons.favorite_border_sharp,
          onTap: () => context.push('/saved-restaurants'),
        ),
      ],
    );
  }

  Widget _buildSearchBar(double t) {
    return GestureDetector(
      // Restaurant/menu search is part of food ordering — not live yet.
      onTap: () => showComingSoonDialog(context),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF0038A8), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'สั่งอะไรดี?',
                style: AppTypography.caption3.copyWith(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildServiceGrid(
    BuildContext context,
    List<Map<String, dynamic>> promos,
  ) {
    // Badge per service, derived from the real promo list. Null → no badge.
    final rideBadge = serviceBadgeOf(promos, 'ride');
    final foodBadge = serviceBadgeOf(promos, 'food');
    final messengerBadge = serviceBadgeOf(promos, 'messenger');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.72,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        children: [
          _buildServiceCard(
            context,
            'เรียกรถ',
            'เรียกครั้งแรก',
            rideBadge?.text,
            rideBadge?.color,
            AppAssets.ic3dRide,
            onTap: () => _openWithZoneCheck(
              service: 'ride',
              iconAsset: AppAssets.ic3dRide,
              serviceName: 'เรียกรถ',
              onAvailable: () => context.push('/ride-landing'),
            ),
          ),
          _buildServiceCard(
            context,
            'สั่งอาหาร',
            'ถูกสุดทุกวัน',
            foodBadge?.text,
            foodBadge?.color,
            AppAssets.ic3dFood,
            // Food ordering isn't live yet — show a "coming soon" notice instead
            // of opening the unfinished flow.
            onTap: () => showComingSoonDialog(context),
          ),
          _buildServiceCard(
            context,
            'เมสเซนเจอร์',
            'ส่งของ พัสดุ',
            messengerBadge?.text,
            messengerBadge?.color,
            AppAssets.ic3dMessenger,
            onTap: () => _openWithZoneCheck(
              service: 'messenger',
              iconAsset: AppAssets.ic3dMessenger,
              serviceName: 'ส่งพัสดุ',
              onAvailable: () {
                // If a messenger order is already running, resume it instead of
                // letting the customer start a second one.
                final active =
                    ref.read(activeOrdersControllerProvider).value ?? const [];
                final ongoing = active.where((o) => o.isMessenger);
                if (ongoing.isNotEmpty) {
                  context.push('/messenger/tracking/${ongoing.first.id}');
                } else {
                  context.push('/messenger-booking');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Zone check (SCRUM-99): when [service] isn't open at the customer's current
  /// location, show a **heads-up** dialog — informational only, not a block.
  /// Tapping "รับทราบ" continues into the flow ([onAvailable]) as normal. An
  /// unknown location / error / not-yet-shipped endpoint just proceeds silently.
  Future<void> _openWithZoneCheck({
    required String service,
    required String iconAsset,
    required String serviceName,
    required VoidCallback onAvailable,
  }) async {
    final loc = ref.read(homeControllerProvider).currentLocation;
    if (loc == null) {
      onAvailable(); // no location yet → don't notify
      return;
    }
    final result = await ref
        .read(serviceAreaRepositoryProvider)
        .check(lat: loc.latitude, lng: loc.longitude, service: service);
    if (!mounted) return;
    if (result.available) {
      onAvailable();
      return;
    }
    final area =
        result.areaName.isNotEmpty ? result.areaName : 'พื้นที่ของคุณ';
    // Out of area → notify, then continue into the flow on acknowledge.
    await showComingSoonDialog(
      context,
      title: 'เร็วๆ นี้ในพื้นที่ของคุณ',
      message:
          'บริการ$serviceName ใน$areaกำลังจะเปิดเร็วๆ นี้ ขณะนี้อาจยังไม่มีคนขับพร้อมให้บริการ',
      iconAsset: iconAsset,
      locationLabel: 'ตำแหน่งของคุณ: $area',
    );
    if (mounted) onAvailable(); // proceed after the heads-up
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String subtitle,
    String? promo,
    Color? promoColor,
    String iconAsset, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption4.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (promo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (promoColor ?? Colors.red).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        promo,
                        style: AppTypography.caption5.copyWith(
                          color: promoColor ?? Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              right: -4,
              bottom: -6,
              child: Image.asset(
                iconAsset,
                width: 62,
                height: 62,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Latest articles (massridedelivery.com/blog) ──────────────────────────
  Widget _buildArticlesSection(BuildContext context) {
    final articles =
        <({String image, String category, String title, String date, String url})>[
      (
        image: 'assets/images/article_mass.webp',
        category: 'แนะนำบริการ',
        title: 'MASS คืออะไร? รู้จักซูเปอร์แอปสัญชาติไทยที่ครบจบในแอปเดียว',
        date: '15 มิถุนายน 2026',
        url: 'https://massridedelivery.com/blog/what-is-mass-super-app',
      ),
      (
        image: 'assets/images/article_food.webp',
        category: 'เคล็ดลับ',
        title: '5 เคล็ดลับสั่งอาหารเดลิเวอรีให้คุ้มค่าและอร่อยเหมือนทานที่ร้าน',
        date: '22 มิถุนายน 2026',
        url: 'https://massridedelivery.com/blog/food-delivery-tips',
      ),
      (
        image: 'assets/images/article_ride.webp',
        category: 'ความปลอดภัย',
        title: 'เดินทางปลอดภัยกับ MASS Ride: ฟีเจอร์ความปลอดภัยที่คุณควรรู้',
        date: '28 มิถุนายน 2026',
        url: 'https://massridedelivery.com/blog/ride-safety-features',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Text(
            'ความรู้และเคล็ดลับจาก MASS',
            style: AppTypography.heading5.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 208,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: articles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _articleCard(articles[i]),
          ),
        ),
      ],
    );
  }

  Widget _articleCard(
    ({String image, String category, String title, String date, String url})
    a,
  ) {
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(a.url), mode: LaunchMode.externalApplication),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF110C0A).withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.asset(
                a.image,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.foundationRed100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a.category,
                      style: AppTypography.caption5.copyWith(
                        color: AppColors.foundationRed700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.title,
                    style: AppTypography.label1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        a.date,
                        style: AppTypography.caption5.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'โปรคุ้มตลอดวัน',
                  style: AppTypography.label3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'โดนัท AFTER YOU 3 ชิ้น + พอน เดอ ริง 3 ชิ้น...',
                  style: AppTypography.caption5.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '฿159',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? emoji,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (emoji != null) ...[
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: AppTypography.heading4.copyWith(
              color: const Color(0xFF1C1B1B),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.push(
              Uri(
                path: '/category-list',
                queryParameters: {'title': title},
              ).toString(),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(
                  'ดูทั้งหมด',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgMidOnWhite,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                  size: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalFoodList(BuildContext context) {
    final items = [
      _RecommendationItem(
        id: 'r2',
        title: 'ไข่หมึกทอดราดน้ำ...',
        subtitle: 'เฮงหอยทอดชาวเล - ต...',
        price: '฿119',
        oldPrice: '฿169',
        rating: '4.8',
        deliveryFee: '฿0',
        image:
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
      ),
      _RecommendationItem(
        id: 'r3',
        title: 'ชุดรวมมิตรหมู(ให...',
        subtitle: 'เรือนเพชรสุกี้ - ถนนเลี่...',
        price: '฿379',
        oldPrice: '฿552',
        rating: '4.8',
        deliveryFee: '฿14',
        image:
            'https://images.unsplash.com/photo-1547825407-2d060104b7f8?w=400',
      ),
    ];

    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildFoodCard(context, items[index]),
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, _RecommendationItem item) {
    return GestureDetector(
      onTap: () => context.push('/restaurant/${item.id}'),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AppNetworkImage(
                url: item.image,
                width: double.infinity,
                height: 110,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.caption4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.subtitle,
                    style: AppTypography.caption5.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(item.deliveryFee, style: AppTypography.caption5),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(item.rating, style: AppTypography.caption5),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.price != null)
                        Text(
                          item.price!,
                          style: AppTypography.label3.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(width: 4),
                      if (item.oldPrice != null)
                        Text(
                          item.oldPrice!,
                          style: AppTypography.caption5.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalRestaurantList(BuildContext context) {
    final items = [
      _RecommendationItem(
        id: 'r1',
        title: 'ไก่ทอด ขีดละ 35 - บาง...',
        subtitle: '31 นาที',
        rating: '3.9',
        deliveryFee: '฿0',
        image:
            'https://images.unsplash.com/photo-1562967914-608f82629710?w=400',
      ),
      _RecommendationItem(
        id: 'r4',
        title: 'ติดแซ่บ หมูปิ้ง ข้าวเหนี...',
        subtitle: '37 นาที',
        rating: '4.7',
        deliveryFee: '฿0',
        image:
            'https://images.unsplash.com/photo-1562967914-608f82629710?w=400',
      ),
    ];

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _buildRestaurantCard(context, items[index]),
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, _RecommendationItem item) {
    return GestureDetector(
      onTap: () => context.push('/restaurant/${item.id}'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AppNetworkImage(
                url: item.image,
                width: double.infinity,
                height: 120,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.caption4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(item.deliveryFee, style: AppTypography.caption5),
                      const SizedBox(width: 8),
                      Text(item.subtitle, style: AppTypography.caption5),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(item.rating, style: AppTypography.caption5),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.confirmation_number,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ใส่โค้ด "LINEMAN"',
                  style: AppTypography.label3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ลดสูงสุด 50%* ไม่มีขั้นต่ำ',
                  style: AppTypography.caption5.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}

class SShapeClipper extends CustomClipper<Path> {
  final double progress;

  SShapeClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    // When progress is 0 (collapsed), we want a flatter curve
    // When progress is 1 (expanded), we want a more pronounced S-shape
    final double curveHeight = 30.0 * progress;

    path.lineTo(0, size.height - curveHeight);

    // Smooth S-shape using two quadratic beziers or one cubic
    // We'll use cubic for a more elegant S-flow
    path.cubicTo(
      size.width * 0.3,
      size.height + curveHeight * 1.2, // Dip down on the left
      size.width * 0.7,
      size.height - curveHeight * 2.5, // Arch up on the right
      size.width,
      size.height - curveHeight * 0.8, // End point
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant SShapeClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

class _RecommendationItem {
  final String id;
  final String title;
  final String subtitle;
  final String? price;
  final String? oldPrice;
  final String rating;
  final String deliveryFee;
  final String image;

  _RecommendationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.price,
    this.oldPrice,
    required this.rating,
    required this.deliveryFee,
    required this.image,
  });
}
