import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/core/widgets/async_state_view.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_cart_controller.dart';
import 'package:customer_app/features/food_order/presentation/controllers/restaurant_detail_controller.dart';
import 'package:customer_app/features/food_order/presentation/widgets/bottom_cart_bar.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:customer_app/features/food_order/presentation/widgets/category_items_list.dart';
import 'package:customer_app/features/food_order/presentation/widgets/for_you_section.dart';
import 'package:customer_app/features/food_order/presentation/widgets/restaurant_info_card.dart';
import 'package:customer_app/features/home/presentation/widgets/menu_item_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  final String? restaurantId;
  const RestaurantDetailScreen({super.key, this.restaurantId});

  void _showClearCartDialog(
    BuildContext context,
    WidgetRef ref,
    MenuItemModel item,
    int quantity,
    List<ModifierModel> selectedModifiers,
    String restaurantId,
    String restaurantName,
    String restaurantImageUrl,
    String notes,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เริ่มตะกร้าใหม่?'),
        content: const Text(
          'คุณมีรายการอาหารจากร้านอื่นอยู่ในตะกร้า ต้องการล้างตะกร้าเพื่อสั่งอาหารจากร้านนี้แทนหรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(foodCartControllerProvider.notifier)
                  .forceAddItem(
                    item: item,
                    quantity: quantity,
                    selectedModifiers: selectedModifiers,
                    restaurantId: restaurantId,
                    restaurantName: restaurantName,
                    restaurantImageUrl: restaurantImageUrl,
                    notes: notes,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('เริ่มตะกร้าใหม่แล้ว')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'เริ่มใหม่',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _openItemDetail(
    BuildContext context,
    WidgetRef ref,
    MenuItemModel item,
    String restaurantId,
    String restaurantName,
    String restaurantImageUrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuItemBottomSheet(
        item: item,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        restaurantImageUrl: restaurantImageUrl,
        onAddToCart: (quantity, totalPrice, selectedModifiers, notes) {
          final success = ref
              .read(foodCartControllerProvider.notifier)
              .addItem(
                item: item,
                quantity: quantity,
                selectedModifiers: selectedModifiers,
                restaurantId: restaurantId,
                restaurantName: restaurantName,
                restaurantImageUrl: restaurantImageUrl,
                notes: notes,
              );
          if (!success) {
            _showClearCartDialog(
              context,
              ref,
              item,
              quantity,
              selectedModifiers,
              restaurantId,
              restaurantName,
              restaurantImageUrl,
              notes,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เพิ่มลงในตะกร้าแล้ว')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = restaurantId ?? 'r1';
    final detailState = ref.watch(restaurantDetailProvider(id));

    if (detailState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const LoadingView(),
      );
    }

    if (detailState.error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ErrorRetryView(
          detail: detailState.error!,
          onRetry: () =>
              ref.read(restaurantDetailProvider(id).notifier).retry(id),
        ),
      );
    }

    final restaurant = detailState.restaurant;
    if (restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ไม่พบร้านค้า')),
        body: const Center(child: Text('ไม่พบข้อมูลร้านค้าที่คุณเลือก')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomCartBar(restaurantId: id),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, ref, restaurant),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                if (detailState.promos.isNotEmpty) ...[
                  _buildPromotionsSection(context, ref, detailState.promos),
                  const SizedBox(height: 16),
                ],
                // Faked from the first few menu items — no recommendation API.
                if (FeatureFlags.foodForYouStrip)
                  ForYouSection(
                    menuCategories: detailState.menuCategories,
                    restaurant: restaurant,
                    onItemTap: (item) => _openItemDetail(
                      context,
                      ref,
                      item,
                      restaurant.id,
                      restaurant.restaurantName,
                      restaurant.imageUrl ?? '',
                    ),
                  ),
              ],
            ),
          ),
          for (final category in detailState.menuCategories) ...[
            if (category.isActive && category.items.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Text(category.name, style: AppTypography.heading4),
                ),
              ),
              CategoryItemsList(
                items: category.items,
                restaurant: restaurant,
                onItemTap: (item) => _openItemDetail(
                  context,
                  ref,
                  item,
                  restaurant.id,
                  restaurant.restaurantName,
                  restaurant.imageUrl ?? '',
                ),
              ),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    WidgetRef ref,
    RestaurantProfileModel restaurant,
  ) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leadingWidth: 0,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final settings = context
              .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
          if (settings == null) return const SizedBox.shrink();

          final deltaExtent = settings.maxExtent - settings.minExtent;
          final t =
              (1.0 -
                      (settings.currentExtent - settings.minExtent) /
                          deltaExtent)
                  .clamp(0.0, 1.0);

          return Opacity(
            opacity: t > 0.8 ? (t - 0.8) * 5 : 0.0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        restaurant.restaurantName,
                        style: AppTypography.caption3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (restaurant.categories.isNotEmpty)
                        Text(
                          restaurant.categories.join(', '),
                          style: AppTypography.caption5.copyWith(
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    restaurant.isSaved ? Icons.favorite : Icons.favorite_border,
                    color: restaurant.isSaved ? Colors.red : Colors.black,
                  ),
                  onPressed: () => ref
                      .read(restaurantDetailProvider(restaurant.id).notifier)
                      .toggleSave(),
                ),
              ],
            ),
          );
        },
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final settings = context
              .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
          if (settings == null) return const SizedBox.shrink();

          final deltaExtent = settings.maxExtent - settings.minExtent;
          final t =
              (1.0 -
                      (settings.currentExtent - settings.minExtent) /
                          deltaExtent)
                  .clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: (1.0 - t).clamp(0.0, 1.0),
                  child: Image.network(
                    restaurant.imageUrl ??
                        'https://plus.unsplash.com/premium_photo-1694141253763-209b4c8f8ace?w=600',
                    fit: BoxFit.cover,
                  ),
                ),
                Opacity(
                  opacity: (1.0 - t).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: (1.0 - t) > 0.5 ? ((1.0 - t) - 0.5) * 2 : 0.0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCircularButton(
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          _buildCircularButton(
                            icon: restaurant.isSaved
                                ? Icons.favorite
                                : Icons.favorite_border,
                            iconColor: restaurant.isSaved
                                ? Colors.red
                                : Colors.black,
                            onPressed: () => ref
                                .read(
                                  restaurantDetailProvider(
                                    restaurant.id,
                                  ).notifier,
                                )
                                .toggleSave(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: (1.0 - t) * 16,
                  child: Opacity(
                    opacity: (1.0 - t) > 0.2 ? ((1.0 - t) - 0.2) / 0.8 : 0.0,
                    child: RestaurantInfoCard(restaurant: restaurant),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    Color? iconColor,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: iconColor ?? Colors.black, size: 20),
        ),
      ),
    );
  }

  Widget _buildPromotionsSection(
    BuildContext context,
    WidgetRef ref,
    List<PromoModel> promos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'คูปองส่วนลดของร้าน',
                style: AppTypography.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return _buildHorizontalPromoCard(context, ref, promo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalPromoCard(
    BuildContext context,
    WidgetRef ref,
    PromoModel promo,
  ) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD1D1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Left Ticket Notch
            Positioned(
              left: -6,
              top: 39,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Right Ticket Notch
            Positioned(
              right: -6,
              top: 39,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Coupon Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          promo.code,
                          style: AppTypography.caption3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          promo.title,
                          style: AppTypography.caption4.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          promo.description,
                          style: AppTypography.caption5.copyWith(
                            color: Colors.black54,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // No clip-to-account endpoint; "เก็บ" only pre-fills the code
                  // locally (SCRUM-44). Hidden until a collect API exists.
                  if (FeatureFlags.foodCouponCollect) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(checkoutProvider.notifier)
                            .updatePromoCode(promo.code);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'เก็บคูปอง "${promo.code}" สำเร็จ! คูปองจะถูกปรับใช้ที่หน้าชำระเงิน',
                            ),
                            backgroundColor: AppColors.primary,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'เก็บ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
