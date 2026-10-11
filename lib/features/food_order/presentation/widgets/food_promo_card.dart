import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Food checkout coupon — the shared ticket [CouponCard] (same look as every
/// other promo list), plus the food-only rules: a promo whose minimum order
/// isn't met yet is greyed out and can't be applied, with an "order ฿X more"
/// shortcut back to the menu.
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

    return CouponCard(
      data: CouponCardData.fromFoodPromo(promo),
      isSelected: isSelected,
      isEnabled: isSelected || isUsable,
      onApply: () =>
          ref.read(checkoutProvider.notifier).updatePromoCode(promo.code),
      onCancel: () =>
          ref.read(checkoutProvider.notifier).updatePromoCode(null),
      footer: (!isUsable && amountNeeded > 0)
          ? _AddMoreBanner(amountNeeded: amountNeeded, context: context)
          : null,
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
