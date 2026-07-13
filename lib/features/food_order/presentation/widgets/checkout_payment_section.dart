import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutPaymentSection extends ConsumerWidget {
  const CheckoutPaymentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: () => _showPaymentBottomSheet(context, ref, checkoutState.paymentMethod),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชำระเงินโดย', style: AppTypography.label2),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      checkoutState.paymentMethod == 'CASH' ? Icons.attach_money : Icons.credit_card,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      checkoutState.paymentMethod == 'CASH' ? 'เงินสด' : 'บัตรเครดิต/เดบิต',
                      style: AppTypography.body1,
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentBottomSheet(BuildContext context, WidgetRef ref, String currentPaymentMethod) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เลือกวิธีการชำระเงิน', style: AppTypography.heading4),
            const SizedBox(height: 20),
            _buildPaymentOptionTile(
              context: context,
              ref: ref,
              currentPaymentMethod: currentPaymentMethod,
              id: 'CASH',
              title: 'เงินสด',
              icon: Icons.attach_money,
            ),
            const SizedBox(height: 12),
            _buildPaymentOptionTile(
              context: context,
              ref: ref,
              currentPaymentMethod: currentPaymentMethod,
              id: 'CARD',
              title: 'บัตรเครดิต/เดบิต',
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required BuildContext context,
    required WidgetRef ref,
    required String currentPaymentMethod,
    required String id,
    required String title,
    required IconData icon,
  }) {
    final isSelected = currentPaymentMethod == id;
    return InkWell(
      onTap: () {
        ref.read(checkoutProvider.notifier).updatePaymentMethod(id);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.black : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.black : Colors.black87),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTypography.body1.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.black : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.black),
          ],
        ),
      ),
    );
  }
}
