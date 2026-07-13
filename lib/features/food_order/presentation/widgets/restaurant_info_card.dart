import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:flutter/material.dart';

class RestaurantInfoCard extends StatelessWidget {
  final RestaurantProfileModel restaurant;

  const RestaurantInfoCard({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(
                  restaurant.imageUrl ??
                      'https://plus.unsplash.com/premium_photo-1694141253763-209b4c8f8ace?w=600',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  restaurant.restaurantName,
                  style: AppTypography.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (restaurant.categories.isNotEmpty)
                  Text(
                    restaurant.categories.join(', '),
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.semanticGrayNeutralFgMidOnGray,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      restaurant.rating.toStringAsFixed(1),
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgMidOnGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${restaurant.deliveryFee == 0 ? 'ส่งฟรี' : '฿${restaurant.deliveryFee?.toStringAsFixed(0) ?? '0'}'} · ${restaurant.durationMin ?? 25} นาที',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgMidOnGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
