import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/promo_card.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoodPromoCard extends ConsumerWidget {
  final PromoModel promo;
  final bool isSelected;
  final double foodTotal;

  const FoodPromoCard({
    super.key,
    required this.promo,
    required this.isSelected,
    required this.foodTotal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUsable = foodTotal >= promo.minOrder;
    final amountNeeded = promo.minOrder - foodTotal;
    final accentColor = isSelected
        ? AppColors.primary
        : isUsable
            ? AppColors.primary
            : Colors.grey[300]!;

    return PromoCardShell(
      isSelected: isSelected,
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PromoIconTile(active: isSelected || isUsable),
              const SizedBox(width: 12),
              // Promo details – Expanded ensures bounded width
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Code + badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          promo.code,
                          style: AppTypography.label2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primary
                                : isUsable
                                    ? Colors.black87
                                    : Colors.grey[500],
                          ),
                        ),
                        _StatusBadge(isUsable: isUsable, promo: promo),
                        if (promo.tag != null && promo.tag!.isNotEmpty)
                          _TagBadge(tag: promo.tag!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promo.title,
                      style: AppTypography.caption4.copyWith(
                        color: isUsable ? Colors.black87 : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      promo.description,
                      style: AppTypography.caption5.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Apply / Cancel button
                    Align(
                      alignment: Alignment.centerRight,
                      child: PromoApplyButton(
                        isSelected: isSelected,
                        isEnabled: isUsable,
                        onApply: () => ref
                            .read(checkoutProvider.notifier)
                            .updatePromoCode(promo.code),
                        onCancel: () => ref
                            .read(checkoutProvider.notifier)
                            .updatePromoCode(null),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // "Add more food" banner for almost-usable promos
          if (!isUsable && amountNeeded > 0) ...[
            const SizedBox(height: 12),
            _AddMoreBanner(amountNeeded: amountNeeded, context: context),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Sub-widgets (extracted for readability)
// ─────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isUsable;
  final PromoModel promo;
  const _StatusBadge({required this.isUsable, required this.promo});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isUsable ? AppColors.foundationRed100 : Colors.amber[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isUsable
            ? 'ใช้ได้'
            : 'สั่งขั้นต่ำ ฿${promo.minOrder.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 9,
          color: isUsable ? AppColors.primary : Colors.amber[800],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String tag;
  const _TagBadge({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 9,
          color: Colors.blue[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AddMoreBanner extends StatelessWidget {
  final double amountNeeded;
  final BuildContext context;
  const _AddMoreBanner({required this.amountNeeded, required this.context});

  @override
  Widget build(BuildContext outerContext) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.pop(context); // Close coupon screen
        Navigator.pop(context); // Return to restaurant menu
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber[100]!),
        ),
        child: Row(
          children: [
            Icon(Icons.add_shopping_cart_outlined,
                size: 14, color: Colors.amber[900]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'สั่งเพิ่มอีก ฿${amountNeeded.toStringAsFixed(0)} เพื่อใช้คูปองนี้',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.amber[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'เพิ่มอาหาร',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.chevron_right, size: 14, color: Colors.amber[900]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
