import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PopularCategoriesWidget extends StatelessWidget {
  final List<CategoryModel> categories;

  const PopularCategoriesWidget({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => context.push(
                Uri(
                  path: '/category-list',
                  queryParameters: {'title': 'หมวดหมู่ยอดนิยม'},
                ).toString(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('หมวดหมู่ยอดนิยม', style: AppTypography.heading4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      context.push(
                        Uri(
                          path: '/category-list',
                          queryParameters: {
                            'categoryId': cat.id,
                            'title': cat.nameTh ?? cat.name ?? '',
                          },
                        ).toString(),
                      );
                    },
                    child: Column(
                      children: [
                        // The category API carries no image, so show a neutral
                        // icon instead of a hardcoded stock photo.
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.foundationGreen100,
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: AppColors.foundationGreen600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 75,
                          child: Text(
                            cat.nameTh ?? cat.name ?? '',
                            style: AppTypography.caption5.copyWith(
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
