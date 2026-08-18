import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/core/widgets/async_state_view.dart';
import 'package:customer_app/core/widgets/hero_header.dart';
import 'package:customer_app/features/food_delivery/presentation/controllers/food_discovery_controller.dart';
import 'package:customer_app/features/food_delivery/presentation/widgets/popular_categories_widget.dart';
import 'package:customer_app/features/food_delivery/presentation/widgets/quick_promos_widget.dart';
import 'package:customer_app/features/food_delivery/presentation/widgets/restaurant_feed_widget.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_cart_controller.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/food_order/presentation/screens/checkout_screen.dart';
import 'package:customer_app/features/active_orders/presentation/widgets/active_orders_banner.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/core/widgets/app_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:go_router/go_router.dart';

class FoodDeliveryScreen extends ConsumerStatefulWidget {
  const FoodDeliveryScreen({super.key});

  @override
  ConsumerState<FoodDeliveryScreen> createState() => _FoodDeliveryScreenState();
}

class _FoodDeliveryScreenState extends ConsumerState<FoodDeliveryScreen> {
  bool _showBottomPromo = true;

  @override
  Widget build(BuildContext context) {
    // The cart is intentionally NOT watched here: a cart edit must not rebuild
    // this whole CustomScrollView + restaurant feed. The floating cart bar
    // (_FoodCartBar) watches the cart in isolation and rebuilds by itself.
    final discoveryState = ref.watch(foodDiscoveryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () =>
                ref.read(foodDiscoveryProvider.notifier).refreshFeed(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                discoveryState.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoadingView(),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorRetryView(
                      message: 'ไม่สามารถโหลดข้อมูลได้',
                      detail: err.toString(),
                      onRetry: () => ref
                          .read(foodDiscoveryProvider.notifier)
                          .refreshFeed(),
                    ),
                  ),
                  data: (data) {
                    return SliverMainAxisGroup(
                      slivers: [
                        const SliverToBoxAdapter(child: ActiveOrdersBanner()),
                        if (FeatureFlags.foodPromoBanners)
                          const SliverToBoxAdapter(child: QuickPromosWidget()),
                        SliverToBoxAdapter(
                          child: PopularCategoriesWidget(
                            categories: data.categories,
                          ),
                        ),
                        for (final section in data.sections)
                          // Hide a section entirely (incl. its header) when it
                          // has no items.
                          if (section.items.isNotEmpty) ...[
                            if (section.title != null &&
                                section.title!.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 24,
                                  bottom: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _sectionTitleTh(section.title!),
                                      style: AppTypography.heading4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (section.layout == 'GRID_VERTICAL')
                            RestaurantFeedWidget(restaurants: section.items)
                          else
                            Builder(
                              builder: (context) {
                                final titleLower = (section.title ?? '')
                                    .toLowerCase();
                                final idLower = section.id.toLowerCase();
                                final isOrderAgain =
                                    idLower.contains('again') ||
                                    titleLower.contains('again') ||
                                    titleLower.contains('ล่าสุด');
                                final isPopular =
                                    idLower.contains('popular') ||
                                    titleLower.contains('popular') ||
                                    titleLower.contains('ยอดนิยม');

                                final double listHeight = isOrderAgain
                                    ? 175.0
                                    : (isPopular ? 215.0 : 130.0);

                                return SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: listHeight,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: section.items.length,
                                      itemBuilder: (context, index) {
                                        final item = section.items[index];
                                        if (isOrderAgain) {
                                          return _buildOrderAgainCard(
                                            context,
                                            item,
                                          );
                                        } else if (isPopular) {
                                          return _buildPopularRestaurantCard(
                                            context,
                                            item,
                                          );
                                        } else {
                                          final restId = item.id;
                                          return GestureDetector(
                                            onTap: () {
                                              if (item.actionType ==
                                                      'RESTAURANT' ||
                                                  item.actionValue != null) {
                                                context.push(
                                                  '/restaurant/${item.actionValue ?? restId}',
                                                );
                                              }
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                right: 12,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: AppNetworkImage(
                                                  url: item.imageUrl,
                                                  width: 220,
                                                  height: 130,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ],
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),

          // Bottom cart bar — self-contained; watches the cart on its own so
          // cart edits don't rebuild the feed above.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FoodCartBar(),
          ),

          // Bottom Promo Banner — hardcoded promo claims, no provider.
          if (FeatureFlags.foodPromoBanners && _showBottomPromo)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildBottomPromoBanner(),
            ),
        ],
      ),
    );
  }

  /// Localise the (often English) feed section titles to Thai.
  String _sectionTitleTh(String title) {
    final t = title.toLowerCase();
    if (t.contains('popular') || t.contains('ยอดนิยม')) return 'ร้านยอดนิยม';
    if (t.contains('nearby') || t.contains('near you')) return 'ร้านใกล้คุณ';
    if (t.contains('again') || t.contains('ล่าสุด')) return 'สั่งอีกครั้ง';
    if (t.contains('recommend')) return 'แนะนำสำหรับคุณ';
    return title;
  }

  SliverAppBar _buildSliverAppBar() {
    final foodAddress = ref.watch(
      homeControllerProvider.select(
        (state) => state.foodAddress ?? 'ระบุสถานที่ส่งอาหาร',
      ),
    );

    return SliverAppBar(
      pinned: true,
      floating: false,
      // Tightened so the search bar sits closer under the address; extra room
      // for the wave cut at the bottom.
      expandedHeight: 182,
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: GestureDetector(
        onTap: () => context.push('/food-place-search'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'จัดส่งที่',
              style: AppTypography.caption5.copyWith(color: Colors.white70),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    foodAddress,
                    style: AppTypography.caption3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
      actions: const [],
      flexibleSpace: FlexibleSpaceBar(
        // Wave-clipped bottom edge to match the messenger / ride hero header.
        background: ClipPath(
          clipper: HeroWaveClipper(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accentRedDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                const HeroPatternOverlay(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GestureDetector(
                        onTap: () => context.push('/item-search'),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              const Icon(Icons.search, color: Colors.black54),
                              const SizedBox(width: 12),
                              Text(
                                'ค้นหาร้านหรือเมนูอาหาร',
                                style: AppTypography.caption3.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Clearance so the search bar clears the wave cut below.
                    const SizedBox(height: 44),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPromoBanner() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3ED),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.foundationOrange600,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.percent, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'โค้ดลด ฿70 + เมนูลด 40%',
                  style: AppTypography.caption2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ค่าส่งเริ่ม ฿0 สั่งด่วน!',
                  style: AppTypography.caption4.copyWith(color: Colors.black87),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
            onPressed: () {
              setState(() {
                _showBottomPromo = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderAgainCard(BuildContext context, HomeSectionItemModel item) {
    final restId = item.actionValue ?? item.id;
    return GestureDetector(
      onTap: () {
        context.push('/restaurant/$restId');
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AppNetworkImage(
                url: item.imageUrl,
                width: 120,
                height: 105,
                fallbackIcon: Icons.restaurant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                item.restaurantName ?? item.title ?? item.name ?? 'ร้านอาหาร',
                style: AppTypography.caption4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularRestaurantCard(
    BuildContext context,
    HomeSectionItemModel item,
  ) {
    final restId = item.actionValue ?? item.id;

    final hasAd = item.badges.any((b) => b.title?.toLowerCase() == 'ad');

    final otherBadge = item.badges.firstWhere(
      (b) => b.title?.toLowerCase() != 'ad',
      orElse: () => const HomeSectionItemBadgeModel(title: null),
    );

    return GestureDetector(
      onTap: () {
        context.push('/restaurant/$restId');
      },
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AppNetworkImage(
                    url: item.imageUrl,
                    width: 175,
                    height: 110,
                    fallbackIcon: Icons.restaurant,
                  ),
                ),
                if (hasAd)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ad',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.restaurantName ??
                        item.title ??
                        item.name ??
                        'ร้านอาหาร',
                    style: AppTypography.caption4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (otherBadge.title != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3F51B5), Color(0xFF00E676)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            otherBadge.title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        item.deliveryFee == null || item.deliveryFee == 0
                            ? '฿0'
                            : '฿${item.deliveryFee!.toStringAsFixed(0)}',
                        style: AppTypography.caption5.copyWith(
                          color: AppColors.foundationBlue800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '|',
                        style: AppTypography.caption5.copyWith(
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.durationMin != null
                              ? '${item.durationMin} นาที'
                              : '— นาที',
                          style: AppTypography.caption5.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        item.rating != null
                            ? item.rating!.toStringAsFixed(1)
                            : '4.5',
                        style: AppTypography.caption5.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
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
}

/// Floating cart pill. Watches only the derived `(count, total)` from the cart
/// controller via `.select`, so it rebuilds in isolation on cart edits without
/// touching the restaurant feed above it.
class _FoodCartBar extends ConsumerWidget {
  const _FoodCartBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (cartCount, cartTotal) = ref.watch(
      foodCartControllerProvider.select((s) => (s.totalQuantity, s.foodTotal)),
    );
    if (cartCount == 0) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CheckoutScreen()),
            );
          },
          child: Container(
            height: 56,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.foundationGreen500,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '$cartCount รายการ',
                  style: AppTypography.caption3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '฿${cartTotal.toStringAsFixed(0)}',
                  style: AppTypography.caption3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
