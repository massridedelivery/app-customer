import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/core/widgets/async_state_view.dart';
import 'package:customer_app/features/food_delivery/presentation/controllers/food_discovery_controller.dart';
import 'package:customer_app/features/food_delivery/presentation/widgets/popular_categories_widget.dart';
import 'package:customer_app/features/food_delivery/presentation/widgets/quick_promos_widget.dart';
import 'package:customer_app/features/food_delivery/presentation/widgets/restaurant_feed_widget.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_cart_controller.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/food_order/presentation/screens/checkout_screen.dart';
import 'package:customer_app/features/active_orders/presentation/widgets/active_orders_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:go_router/go_router.dart';

class FoodDeliveryScreen extends ConsumerStatefulWidget {
  const FoodDeliveryScreen({super.key});

  @override
  ConsumerState<FoodDeliveryScreen> createState() => _FoodDeliveryScreenState();
}

class _FoodDeliveryScreenState extends ConsumerState<FoodDeliveryScreen> {
  int _selectedTab = 0; // 0: จัดส่ง, 1: รับที่ร้าน, 2: ดีลทานที่ร้าน
  bool _showBottomPromo = true;

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(foodDiscoveryProvider);
    ref.watch(foodCartControllerProvider);
    final cartNotifier = ref.read(foodCartControllerProvider.notifier);

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
                        for (final section in data.sections) ...[
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
                                      section.title!,
                                      style: AppTypography.heading4,
                                    ),
                                    if (section.layout != 'GRID_VERTICAL')
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE4FDF2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Color(0xFF0D995C),
                                          size: 16,
                                        ),
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
                                                child: Image.network(
                                                  item.imageUrl ?? '',
                                                  width: 220,
                                                  height: 130,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        width: 220,
                                                        height: 130,
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons.image,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
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

          // Floating Cart
          Positioned(
            right: 16,
            bottom: _showBottomPromo ? 100 : 32,
            child: _buildFloatingCart(
              cartNotifier.totalQuantity,
              cartNotifier.foodTotal,
            ),
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

  SliverAppBar _buildSliverAppBar() {
    final foodAddress = ref.watch(
      homeControllerProvider.select(
        (state) => state.foodAddress ?? 'ระบุสถานที่ส่งอาหาร',
      ),
    );

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 190,
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
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accentRedDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
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
              const SizedBox(height: 12),
              // Delivery Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildTab(0, 'จัดส่ง', Icons.delivery_dining),
                    ),
                    // Backend is delivery-only; these tabs never filtered the
                    // feed (SCRUM-44). Hidden until pickup/dine-in is supported.
                    if (FeatureFlags.foodPickupDineInTabs) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTab(1, 'รับที่ร้าน', Icons.storefront),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTab(
                          2,
                          'ดีลทานที่ร้าน',
                          Icons.local_activity,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Rounded bottom edge
              Container(
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String text, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTypography.caption5.copyWith(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCart(int cartCount, double cartTotal) {
    if (cartCount == 0) return const SizedBox.shrink();
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const CheckoutScreen()));
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.foundationGreen500,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '$cartCount รายการ • ฿${cartTotal.toStringAsFixed(0)}',
              style: AppTypography.caption3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? Image.network(
                      item.imageUrl!,
                      width: 120,
                      height: 105,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 120,
                        height: 105,
                        color: Colors.grey[100],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 105,
                      color: Colors.grey[100],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
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
                  child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      ? Image.network(
                          item.imageUrl!,
                          width: 175,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 175,
                                height: 110,
                                color: Colors.grey[100],
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : Container(
                          width: 175,
                          height: 110,
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.grey,
                          ),
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
                              ? '${item.durationMin} min'
                              : '20 min',
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
