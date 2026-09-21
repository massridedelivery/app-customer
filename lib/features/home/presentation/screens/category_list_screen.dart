import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/home/presentation/controllers/category_restaurants_controller.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/core/widgets/app_network_image.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CategoryListScreen extends ConsumerWidget {
  final String title;
  final String? categoryId;
  // When set, browse a home-feed section (SCRUM-8) via the section endpoint
  // instead of a category; takes precedence over [categoryId].
  final String? sectionId;

  const CategoryListScreen({
    super.key,
    required this.title,
    this.categoryId,
    this.sectionId,
  });

  bool get _useSection => sectionId != null && sectionId!.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_useSection && categoryId == null) {
      return Scaffold(
        backgroundColor: AppColors.semanticGrayNeutralBgWhite,
        appBar: AppBar(
          title: Text(
            title,
            style: AppTypography.heading4.copyWith(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'ไม่พบข้อมูลหมวดหมู่',
            style: AppTypography.label1.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    final feedAsync = _useSection
        ? ref.watch(sectionRestaurantsProvider(sectionId!))
        : ref.watch(categoryRestaurantsProvider(categoryId!));
    void loadMore() => _useSection
        ? ref.read(sectionRestaurantsProvider(sectionId!).notifier).loadMore()
        : ref.read(categoryRestaurantsProvider(categoryId!).notifier).loadMore();
    void refresh() => _useSection
        ? ref.invalidate(sectionRestaurantsProvider(sectionId!))
        : ref.invalidate(categoryRestaurantsProvider(categoryId!));

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        title: Text(
          title,
          style: AppTypography.heading4.copyWith(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: feedAsync.when(
        data: (feed) {
          final items = feed.items;
          if (items.isEmpty) {
            return Center(
              child: Text(
                'ไม่พบร้านอาหารในหมวดหมู่นี้',
                style: AppTypography.label1.copyWith(color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => refresh(),
            // Endless scroll (SCRUM-8): fetch the next page as the user nears
            // the bottom; a full page implies more, a short one ends it.
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (feed.hasMore &&
                    !feed.loadingMore &&
                    n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                  loadMore();
                }
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildCategoryRestaurantCard(
                          context,
                          items[index],
                        ),
                        childCount: items.length,
                      ),
                    ),
                  ),
                  if (feed.loadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: MassLoadingM(size: 72),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'เกิดข้อผิดพลาดในการโหลดข้อมูล',
                  style: AppTypography.heading4,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: AppTypography.caption4,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRestaurantCard(
    BuildContext context,
    RestaurantProfileModel restaurant,
  ) {
    return InkWell(
      onTap: () {
        context.push('/restaurant/${restaurant.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                    url: restaurant.imageUrl,
                    width: double.infinity,
                    height: 120,
                    fallbackIcon: Icons.image_not_supported,
                  ),
                ),
                if (!restaurant.isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ปิดทำการ',
                            style: AppTypography.caption5.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.restaurantName,
                      style: AppTypography.caption4.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      restaurant.cuisineType ?? 'ร้านอาหาร',
                      style: AppTypography.caption5.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: AppTypography.caption5.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          restaurant.deliveryFee == null ||
                                  restaurant.deliveryFee == 0
                              ? 'ส่งฟรี'
                              : '฿${restaurant.deliveryFee!.toStringAsFixed(0)}',
                          style: AppTypography.caption5.copyWith(
                            color: AppColors.foundationGreen600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
