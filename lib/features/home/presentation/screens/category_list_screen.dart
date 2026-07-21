import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_delivery/data/repositories/food_discovery_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/core/widgets/app_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final categoryRestaurantsProvider =
    FutureProvider.family<List<RestaurantProfileModel>, String>((
      ref,
      categoryId,
    ) async {
      final location = ref.watch(
        homeControllerProvider.select(
          (state) =>
              state.foodLocation ??
              state.pickupLocation ??
              state.currentLocation,
        ),
      );
      final lat = location?.latitude ?? 13.7563;
      final lng = location?.longitude ?? 100.5018;

      final repo = ref.watch(foodDiscoveryRepositoryProvider);
      return await repo.getCategoryRestaurants(
        categoryId: categoryId,
        lat: lat,
        lng: lng,
      );
    });

class CategoryListScreen extends ConsumerWidget {
  final String title;
  final String? categoryId;

  const CategoryListScreen({super.key, required this.title, this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId == null) {
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

    final itemsAsync = ref.watch(categoryRestaurantsProvider(categoryId!));

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
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'ไม่พบร้านอาหารในหมวดหมู่นี้',
                style: AppTypography.label1.copyWith(color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(categoryRestaurantsProvider(categoryId!));
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildCategoryRestaurantCard(context, item);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
