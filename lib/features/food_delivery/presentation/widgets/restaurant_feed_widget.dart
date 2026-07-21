import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/app_network_image.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RestaurantFeedWidget extends StatelessWidget {
  final List<HomeSectionItemModel> restaurants;

  const RestaurantFeedWidget({super.key, required this.restaurants});

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final rest = restaurants[index];
        final id = rest.id;

        return InkWell(
          onTap: () {
            context.push('/restaurant/$id');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppNetworkImage(
                    url: rest.imageUrl,
                    width: 100,
                    height: 100,
                    fallbackIcon: Icons.restaurant,
                    fallbackIconSize: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              rest.restaurantName ?? rest.title ?? 'ร้านอาหาร',
                              style: AppTypography.caption4.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                            ),
                          ),
                          const Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${rest.rating ?? 0.0}',
                            style: AppTypography.caption5.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            rest.deliveryFee == null || rest.deliveryFee == 0
                                ? 'ส่งฟรี'
                                : '฿${rest.deliveryFee}',
                            style: AppTypography.caption5.copyWith(
                              color: AppColors.foundationGreen600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            rest.durationMin != null
                                ? ' • ${rest.durationMin} นาที'
                                : ' • 20+ นาที',
                            style: AppTypography.caption5.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (rest.distanceKm != null)
                            Text(
                              ' • ${rest.distanceKm!.toStringAsFixed(1)} กม.',
                              style: AppTypography.caption5.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (rest.isOpen == false)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ปิดทำการ',
                            style: AppTypography.caption5.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: restaurants.length),
    );
  }
}
