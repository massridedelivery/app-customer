import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/live_food_tracking_controller.dart';

class LiveFoodTrackingPaymentMethod extends ConsumerWidget {
  const LiveFoodTrackingPaymentMethod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethod = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.order?.paymentMethod),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'วิธีการชำระเงิน',
                style: AppTypography.caption4.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.foundationGreen100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  paymentMethod ?? 'CASH',
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.foundationGreen700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                paymentMethod == 'CARD' ? 'บัตรเครดิต' : 'เงินสด',
                style: AppTypography.caption4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
