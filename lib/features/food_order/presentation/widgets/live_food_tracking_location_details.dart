import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/live_food_tracking_controller.dart';

class LiveFoodTrackingLocationDetails extends ConsumerWidget {
  const LiveFoodTrackingLocationDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.order),
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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.storefront,
                color: AppColors.foundationGreen500,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order?.restaurantName ?? 'ร้านค้าผู้ปรุงอาหาร',
                      style: AppTypography.label2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order?.restaurantAddress ??
                          'ร้านอาหารต้นทางอ้างอิงรหัส: ${order?.restaurantId ?? "N/A"}',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgLowOnWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 9),
              child: Container(
                height: 24,
                width: 2,
                color: Colors.grey.shade200,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สถานที่จัดส่งของคุณ', style: AppTypography.label2),
                    const SizedBox(height: 4),
                    Text(
                      order?.deliveryAddress ?? 'ที่อยู่จัดส่ง',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgLowOnWhite,
                      ),
                    ),
                    if (order?.deliveryNotes != null &&
                        order!.deliveryNotes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'โน้ต: ${order.deliveryNotes}',
                        style: AppTypography.caption5.copyWith(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
