import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/live_food_tracking_controller.dart';

/// A PromptPay order that isn't paid yet: the restaurant doesn't see it until
/// the QR is paid (the backend cancels it when the QR expires). Shown when the
/// customer left the QR screen, so they can open it again.
class LiveFoodTrackingPayNow extends ConsumerWidget {
  final String orderId;

  const LiveFoodTrackingPayNow({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.order),
    );
    final unpaid =
        order != null &&
        order.paymentMethod.toUpperCase() == 'PROMPTPAY' &&
        (order.paymentStatus ?? '').toUpperCase() == 'PENDING' &&
        order.status.toUpperCase() != 'CANCELLED';
    if (!unpaid) return const SizedBox.shrink();
    // Held at ฿0 (the app's total said there was something to pay, the
    // server's didn't): there's no QR for ฿0, so it can never be released.
    final cantPay = order.totalAmount <= 0;

    final tracking = '/food-order/tracking/$orderId';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        key: const Key('foodPayNow'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.semanticWarningBgLowOnWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 20,
                  color: AppColors.semanticWarningFgHigh,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cantPay
                        ? 'ชำระเงินคำสั่งซื้อนี้ไม่ได้'
                        : 'ยังไม่ได้ชำระเงิน',
                    style: AppTypography.label2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              cantPay
                  ? 'ยอดเป็น ฿0 จึงสร้าง QR ไม่ได้ กรุณายกเลิกแล้วสั่งใหม่'
                  : 'ร้านจะได้รับคำสั่งซื้อหลังชำระเงินด้วยพร้อมเพย์',
              style: AppTypography.body3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (!cantPay) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('foodPayNowButton'),
                  onPressed: () => context.pushReplacement(
                    '/payment/promptpay',
                    extra: {
                      'orderId': orderId,
                      'onPaidRoute': tracking,
                      'exitRoute': tracking,
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('ชำระเงิน', style: AppTypography.label2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
