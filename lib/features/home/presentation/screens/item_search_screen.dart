import 'dart:async';

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_search_controller.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/core/widgets/app_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ItemSearchScreen extends ConsumerStatefulWidget {
  const ItemSearchScreen({super.key});

  @override
  ConsumerState<ItemSearchScreen> createState() => _ItemSearchScreenState();
}

class _ItemSearchScreenState extends ConsumerState<ItemSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(foodSearchControllerProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(foodSearchControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาร้านหรือเมนูอาหาร',
                      hintStyle: AppTypography.caption4.copyWith(
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(foodSearchControllerProvider.notifier)
                                    .clearSearch();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(searchState),
    );
  }

  Widget _buildBody(FoodSearchState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null) {
      return Center(
        child: Text(
          'เกิดข้อผิดพลาด: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (state.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'ค้นหาของที่อยากกินเลย',
              style: AppTypography.heading4.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (state.restaurantResults.isEmpty) {
      return Center(
        child: Text(
          'ไม่พบผลลัพธ์สำหรับ "${state.query}"',
          style: AppTypography.caption3.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('ร้านอาหาร', style: AppTypography.heading4),
        const SizedBox(height: 12),
        ...state.restaurantResults.map((e) => _buildRestaurantListTile(e)),
      ],
    );
  }

  Widget _buildRestaurantListTile(RestaurantProfileModel restaurant) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push('/restaurant/${restaurant.id}'),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AppNetworkImage(
          url: restaurant.imageUrl,
          width: 50,
          height: 50,
          fallbackIcon: Icons.image_not_supported,
          fallbackIconSize: 20,
        ),
      ),
      title: Text(
        restaurant.restaurantName,
        style: AppTypography.caption3.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(
            restaurant.rating.toStringAsFixed(1),
            style: AppTypography.caption5,
          ),
          const SizedBox(width: 8),
          Text(
            restaurant.durationMin != null
                ? '• ${restaurant.durationMin} นาที'
                : '• 20+ นาที',
            style: AppTypography.caption5,
          ),
          const SizedBox(width: 8),
          Text(
            restaurant.deliveryFee == null || restaurant.deliveryFee == 0
                ? '• ส่งฟรี'
                : '• ฿${restaurant.deliveryFee!.toStringAsFixed(0)}',
            style: AppTypography.caption5.copyWith(
              color:
                  restaurant.deliveryFee == null || restaurant.deliveryFee == 0
                  ? AppColors.foundationGreen600
                  : null,
              fontWeight:
                  restaurant.deliveryFee == null || restaurant.deliveryFee == 0
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ],
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
    );
  }
}
