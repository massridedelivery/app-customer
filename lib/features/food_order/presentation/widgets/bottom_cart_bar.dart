import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_cart_controller.dart';
import 'package:customer_app/features/food_order/presentation/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomCartBar extends ConsumerWidget {
  final String restaurantId;

  const BottomCartBar({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(foodCartControllerProvider);
    final cartNotifier = ref.read(foodCartControllerProvider.notifier);

    final showCart = cartNotifier.totalQuantity > 0 && cart.restaurantId == restaurantId;

    if (!showCart) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CheckoutScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.foundationGreen500,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ตะกร้า • ${cartNotifier.totalQuantity} รายการ',
                style: AppTypography.heading5.copyWith(color: Colors.white),
              ),
              Text(
                '฿${cartNotifier.foodTotal.toStringAsFixed(0)}',
                style: AppTypography.heading4.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
