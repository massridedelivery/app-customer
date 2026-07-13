import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/live_food_tracking_controller.dart';

class LiveFoodTrackingCancelButton extends ConsumerWidget {
  const LiveFoodTrackingCancelButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderStatus = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.orderStatus),
    );

    if (orderStatus != 'PLACED') {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () async {
        try {
          await ref
              .read(liveFoodTrackingControllerProvider.notifier)
              .cancelActiveOrder();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ยกเลิกคำสั่งซื้อเรียบร้อย'),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ไม่สามารถยกเลิกได้: $e')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'ยกเลิกออเดอร์',
          style: AppTypography.caption4.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
