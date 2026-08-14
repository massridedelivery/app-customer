import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/payment/presentation/controllers/credit_cards_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "บัตรเครดิต" — the customer's saved cards (UI-only mock; see
/// [creditCardsProvider]). Tap "เพิ่มบัตรเครดิต" to open the add flow.
class CreditCardListScreen extends ConsumerWidget {
  const CreditCardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(creditCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        title: const Text('บัตรเครดิต', style: AppTypography.heading4),
        backgroundColor: AppColors.semanticGrayNeutralBgWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: cards.isEmpty
          ? const _EmptyCards()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final card = cards[i];
                return Dismissible(
                  key: ValueKey(card.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) =>
                      ref.read(creditCardsProvider.notifier).remove(card.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: CreditCardVisual(
                    brand: card.brand,
                    last4: card.last4,
                    holder: card.holder,
                    expiry: card.expiry,
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/credit-cards/add'),
              icon: const Icon(Icons.add),
              label: Text(
                'เพิ่มบัตรเครดิต',
                style: AppTypography.label1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_off_rounded,
              size: 72,
              color: AppColors.foundationGrayscale300,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีบัตรเครดิต',
              style: AppTypography.heading4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เพิ่มบัตรเพื่อชำระเงินได้สะดวกขึ้น',
              style: AppTypography.body2.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand-styled card visual, reused by the list and the add-card preview.
class CreditCardVisual extends StatelessWidget {
  final CardBrand brand;
  final String last4;
  final String holder;
  final String expiry;

  const CreditCardVisual({
    super.key,
    required this.brand,
    required this.last4,
    required this.holder,
    required this.expiry,
  });

  List<Color> get _gradient => switch (brand) {
    CardBrand.visa => const [Color(0xFF1A1F71), Color(0xFF2A3FA0)],
    CardBrand.mastercard => const [Color(0xFF1C1C1E), Color(0xFF3A3A3C)],
    CardBrand.amex => const [Color(0xFF16A085), Color(0xFF1ABC9C)],
    CardBrand.unknown => const [AppColors.accentRedDeep, AppColors.primary],
  };

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586, // ISO 7810 ID-1 card ratio
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradient,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6C74B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Spacer(),
                Text(
                  cardBrandLabel(brand),
                  style: AppTypography.label1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '••••  ••••  ••••  ${last4.isEmpty ? '••••' : last4}',
              style: AppTypography.heading4.copyWith(
                color: Colors.white,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ชื่อผู้ถือบัตร',
                        style: AppTypography.caption5.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        holder.isEmpty ? 'YOUR NAME' : holder.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'หมดอายุ',
                      style: AppTypography.caption5.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      expiry.isEmpty ? 'MM/YY' : expiry,
                      style: AppTypography.label2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
