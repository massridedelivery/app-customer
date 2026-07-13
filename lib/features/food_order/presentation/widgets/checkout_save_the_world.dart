import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutSaveTheWorld extends ConsumerWidget {
  const CheckoutSaveTheWorld({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('รักษ์โลกกับเรา', style: AppTypography.heading4),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ฉันต้องการช้อนส้อมพลาสติก',
                        style: AppTypography.body1,
                      ),
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: checkoutState.wantCutlery,
                          onChanged: (val) {
                            ref.read(checkoutProvider.notifier).updateWantCutlery(val ?? false);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.foundationGreen100.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ขอบคุณที่ช่วยลดขยะไปถึง 1 ชิ้น',
                              style: AppTypography.body1.copyWith(
                                color: AppColors.foundationGreen600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'คุณได้ช่วยลดภาวะโลกร้อนแล้ว',
                              style: AppTypography.caption4.copyWith(
                                color: AppColors.foundationGreen600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.eco,
                        color: AppColors.foundationGreen500,
                        size: 32,
                      ),
                    ],
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
