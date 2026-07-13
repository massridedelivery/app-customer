import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:flutter/material.dart';

class ForYouSection extends StatelessWidget {
  final List<MenuCategoryModel> menuCategories;
  final RestaurantProfileModel restaurant;
  final void Function(MenuItemModel item) onItemTap;

  const ForYouSection({
    super.key,
    required this.menuCategories,
    required this.restaurant,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<MenuItemModel> allItems = [];
    for (final cat in menuCategories) {
      if (cat.isActive) {
        allItems.addAll(cat.items);
      }
    }

    if (allItems.isEmpty) return const SizedBox.shrink();

    final forYouItems = allItems.where((i) => i.isAvailable).toList();
    if (forYouItems.isEmpty) return const SizedBox.shrink();

    final count = forYouItems.length > 4 ? 4 : forYouItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('สำหรับคุณ', style: AppTypography.heading4),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 0.72,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            final item = forYouItems[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(
                              item.imageUrl ??
                                  'https://plus.unsplash.com/premium_photo-1694141253763-209b4c8f8ace?w=400',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () => onItemTap(item),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.foundationGreen600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: AppTypography.caption3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '฿${item.price.toStringAsFixed(0)}',
                  style: AppTypography.caption3,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
