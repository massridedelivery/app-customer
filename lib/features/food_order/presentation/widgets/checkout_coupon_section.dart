import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:customer_app/features/food_order/presentation/screens/food_coupon_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutCouponSection extends ConsumerWidget {
  const CheckoutCouponSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: () {
          ref.read(checkoutProvider.notifier).fetchAvailablePromos();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FoodCouponScreen(),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('คูปอง', style: AppTypography.label2),
                if (checkoutState.appliedPromoCodes.isNotEmpty)
                  Text(
                    'ใช้คูปอง: ${checkoutState.appliedPromoCodes.join(', ')}',
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Text(
                  checkoutState.appliedPromoCodes.isNotEmpty ? 'เปลี่ยน' : 'ใช้คูปอง',
                  style: AppTypography.caption4.copyWith(
                    color: checkoutState.appliedPromoCodes.isNotEmpty
                        ? AppColors.primary
                        : Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: checkoutState.appliedPromoCodes.isNotEmpty
                      ? AppColors.primary
                      : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


