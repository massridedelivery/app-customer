import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutDeliveryOptions extends ConsumerWidget {
  const CheckoutDeliveryOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutProvider);
    final tiers = checkoutState.estimate?.tiers ?? [];

    DeliveryTierModel? saverTier;
    DeliveryTierModel? standardTier;
    DeliveryTierModel? priorityTier;

    for (final t in tiers) {
      if (t.tier == 'SAVER') saverTier = t;
      if (t.tier == 'STANDARD') standardTier = t;
      if (t.tier == 'PRIORITY') priorityTier = t;
    }

    final saverPrice = saverTier != null
        ? (saverTier.deliveryFee == 0 ? 'ฟรี' : '฿${saverTier.deliveryFee.toStringAsFixed(0)}')
        : '฿15';
    final standardPrice = standardTier != null
        ? (standardTier.deliveryFee == 0 ? 'ฟรี' : '฿${standardTier.deliveryFee.toStringAsFixed(0)}')
        : 'ฟรี';
    final priorityPrice = priorityTier != null
        ? (priorityTier.deliveryFee == 0 ? 'ฟรี' : '฿${priorityTier.deliveryFee.toStringAsFixed(0)}')
        : '฿45';

    final saverMin = saverTier?.estimatedMin ?? 35;
    final standardMin = standardTier?.estimatedMin ?? 25;
    final priorityMin = priorityTier?.estimatedMin ?? 18;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFE1F5FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 20,
                  color: Colors.lightBlue,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ตัวเลือกการจัดส่ง', style: AppTypography.label2),
                  Text(
                    'บริการโดยคนขับในพื้นที่',
                    style: AppTypography.caption4.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDeliveryOptionTile(
            ref: ref,
            id: 'PRIORITY',
            title: 'ส่งด่วน (Priority) • $priorityMin นาที',
            subtitle: 'ส่งตรงรวดเร็วที่สุด ไม่พ่วงออเดอร์',
            price: priorityPrice,
            isSelected: checkoutState.selectedDeliveryOption == 'PRIORITY',
            showInfo: true,
          ),
          const SizedBox(height: 8),
          _buildDeliveryOptionTile(
            ref: ref,
            id: 'STANDARD',
            title: 'ปกติ (Standard) • $standardMin นาที',
            subtitle: 'จัดส่งตามรอบมาตรฐาน',
            price: standardPrice,
            isSelected: checkoutState.selectedDeliveryOption == 'STANDARD',
            isGreenPrice: standardPrice == 'ฟรี',
          ),
          const SizedBox(height: 8),
          _buildDeliveryOptionTile(
            ref: ref,
            id: 'SAVER',
            title: 'ประหยัด (Saver) • $saverMin นาที',
            subtitle: 'ประหยัดค่าส่งมากขึ้น (อาจส่งร่วมกับออเดอร์อื่น)',
            price: saverPrice,
            isSelected: checkoutState.selectedDeliveryOption == 'SAVER',
            showInfo: true,
            isGreenPrice: saverPrice == 'ฟรี',
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptionTile({
    required WidgetRef ref,
    required String id,
    required String title,
    String? subtitle,
    String? price,
    required bool isSelected,
    bool showInfo = false,
    bool isGreenPrice = false,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(checkoutProvider.notifier).updateDeliveryOption(id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.foundationGreen100.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.foundationGreen600 : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (showInfo) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.caption4.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (price != null)
              Text(
                price,
                style: AppTypography.body1.copyWith(
                  color: isGreenPrice ? AppColors.foundationGreen600 : Colors.black87,
                  fontWeight: isGreenPrice ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
