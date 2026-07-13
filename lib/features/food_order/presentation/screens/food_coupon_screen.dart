import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_cart_controller.dart';
import 'package:customer_app/features/food_order/presentation/widgets/food_promo_card.dart';
import 'package:customer_app/features/food_order/presentation/widgets/manual_promo_input_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoodCouponScreen extends ConsumerWidget {
  const FoodCouponScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appliedPromoCodes = ref.watch(
      checkoutProvider.select((state) => state.appliedPromoCodes),
    );
    final isPromoLoading = ref.watch(
      checkoutProvider.select((state) => state.isPromoLoading),
    );
    final promos = ref.watch(
      checkoutProvider.select((state) => state.availablePromos),
    );
    final foodTotal =
        ref.read(foodCartControllerProvider.notifier).foodTotal;

    // Auto-pop back after a promo is successfully applied via the card buttons
    ref.listen<String?>(
      checkoutProvider.select((s) => s.appliedPromoCode),
      (previous, next) {
        if (next != null && next != previous && context.mounted) {
          Navigator.pop(context);
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'เลือกคูปองส่วนลด',
          style: AppTypography.heading4.copyWith(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECTION 1: Manual promo code input (Fixed at the top)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: ManualPromoInputSection(),
            ),

            // SECTION 2: List of promotions (Scrollable, lazy)
            Expanded(
              child: isPromoLoading && promos.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(checkoutProvider.notifier)
                          .fetchAvailablePromos(),
                      color: AppColors.primary,
                      child: promos.isEmpty
                          ? _EmptyPromosView(
                              onRefresh: () => ref
                                  .read(checkoutProvider.notifier)
                                  .fetchAvailablePromos(),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              // header + N cards + footer spacer
                              itemCount: promos.length + 2,
                              itemBuilder: (context, index) {
                                // Header
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      top: 16,
                                      bottom: 12,
                                    ),
                                    child: Text(
                                      'คูปองส่วนลดที่มี',
                                      style: AppTypography.label1.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                // Footer spacer
                                if (index == promos.length + 1) {
                                  return const SizedBox(height: 20);
                                }
                                // Promo card (lazy-built)
                                final promo = promos[index - 1];
                                return FoodPromoCard(
                                  key: ValueKey(promo.code),
                                  promo: promo,
                                  isSelected:
                                      appliedPromoCodes.contains(promo.code),
                                  foodTotal: foodTotal,
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when there are no available promos, still inside RefreshIndicator.
class _EmptyPromosView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyPromosView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'ไม่มีคูปองที่สามารถใช้งานได้ในขณะนี้',
                style: AppTypography.label2.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('โหลดใหม่'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
