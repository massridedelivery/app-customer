import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_cart_controller.dart';
import 'package:customer_app/features/food_order/presentation/states/food_cart_state.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/core/widgets/app_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutOrderItems extends ConsumerWidget {
  const CheckoutOrderItems({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(foodCartControllerProvider);
    final cartNotifier = ref.read(foodCartControllerProvider.notifier);
    final checkoutState = ref.watch(checkoutProvider);

    final double foodSubtotal = cartNotifier.foodTotal;
    double deliveryFee = 0.0;

    final tiers = checkoutState.estimate?.tiers ?? [];
    DeliveryTierModel? selectedTier;
    for (final t in tiers) {
      if (t.tier == checkoutState.selectedDeliveryOption) {
        selectedTier = t;
        break;
      }
    }

    if (selectedTier != null) {
      deliveryFee = selectedTier.deliveryFee;
    } else {
      if (checkoutState.selectedDeliveryOption == 'PRIORITY') {
        deliveryFee = 45;
      } else if (checkoutState.selectedDeliveryOption == 'SAVER') {
        deliveryFee = 15;
      } else {
        deliveryFee = 25;
      }
    }

    final double totalAmount = (foodSubtotal + deliveryFee - checkoutState.validatedPromoDiscount).clamp(0.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('รายการอาหารที่สั่ง', style: AppTypography.heading4),
          const SizedBox(height: 24),
          for (int i = 0; i < cart.items.length; i++) ...[
            _buildCartItemRow(ref, cart.items[i], i),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          _buildSummaryRow(
            title: 'ค่าอาหาร',
            value: '฿${foodSubtotal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            title: 'ค่าจัดส่ง',
            value: deliveryFee == 0 ? 'ฟรี' : '฿${deliveryFee.toStringAsFixed(0)}',
            showInfo: true,
          ),
          if (checkoutState.validatedPromoDiscount > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(
              title: 'ส่วนลดคูปอง',
              value: '-฿${checkoutState.validatedPromoDiscount.toStringAsFixed(0)}',
              valueColor: AppColors.primary,
            ),
          ],
          const SizedBox(height: 12),
          _buildSummaryRow(
            title: 'รวมทั้งหมด',
            value: '฿${totalAmount.toStringAsFixed(0)}',
            valueColor: AppColors.foundationGreen600,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemRow(WidgetRef ref, CartItem cartItem, int index) {
    double itemSinglePrice = cartItem.item.price;
    for (final m in cartItem.selectedModifiers) {
      itemSinglePrice += m.price;
    }
    final double itemSubtotal = itemSinglePrice * cartItem.quantity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AppNetworkImage(
            url: cartItem.item.imageUrl,
            width: 80,
            height: 60,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cartItem.item.nameTh, style: AppTypography.label2),
              if (cartItem.selectedModifiers.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  cartItem.selectedModifiers.map((e) => e.name).join(', '),
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgLowOnGray,
                  ),
                ),
              ],
              if (cartItem.notes.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'หมายเหตุ: ${cartItem.notes}',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgLowOnGray,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  ref.read(foodCartControllerProvider.notifier).removeItem(index);
                },
                child: Text(
                  'ลบรายการ',
                  style: AppTypography.heading5.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '฿${itemSubtotal.toStringAsFixed(0)}',
              style: AppTypography.body1.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    ref
                        .read(foodCartControllerProvider.notifier)
                        .updateQuantity(index, cartItem.quantity - 1);
                  },
                  child: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${cartItem.quantity}',
                    style: AppTypography.body1.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ref
                        .read(foodCartControllerProvider.notifier)
                        .updateQuantity(index, cartItem.quantity + 1);
                  },
                  child: const Icon(Icons.add_circle_outline, size: 20, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required String title,
    required String value,
    bool showInfo = false,
    bool isBold = false,
    Color? valueColor = AppColors.semanticGrayNeutralFgHigh,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTypography.body1.copyWith(
                color: valueColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
            ],
          ],
        ),
        Text(
          value,
          style: AppTypography.body1.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
