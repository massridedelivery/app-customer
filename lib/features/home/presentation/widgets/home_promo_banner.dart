import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A horizontal carousel of the customer's active promotions, driven by the
/// real `GET /api/customer/promo/list` (via [promoListProvider]). Renders
/// nothing while loading, on error, or when there are no promos — so it never
/// leaves an empty header behind.
class HomePromoBanner extends ConsumerWidget {
  const HomePromoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(promoListProvider);

    return promosAsync.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (raw) {
        final promos = raw
            .map(
              (e) => e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            )
            .toList();
        if (promos.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Text(
                    'โปรโมชั่นสำหรับคุณ',
                    style: AppTypography.heading5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/promos'),
                    child: Text(
                      'ดูทั้งหมด',
                      style: AppTypography.label2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: promos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, i) => _PromoCard(promo: promos[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  final Map<String, dynamic> promo;
  const _PromoCard({required this.promo});

  String get _title =>
      (promo['title'] ?? promo['name'] ?? 'โปรโมชั่น').toString();

  String? get _code => promo['code']?.toString();

  num get _minSpend {
    final v = promo['min_order'] ?? promo['min_spend'] ?? 0;
    return v is num ? v : num.tryParse(v.toString()) ?? 0;
  }

  /// Headline like "ลด ฿100" / "ลด 20%", derived from discount_type + value.
  String get _headline {
    final type = (promo['discount_type'] ?? '').toString().toLowerCase();
    final rawVal = promo['discount_value'] ?? promo['discount'] ?? 0;
    final num value = rawVal is num
        ? rawVal
        : num.tryParse(rawVal.toString()) ?? 0;
    if (value <= 0) return _title;
    if (type == 'percentage') return 'ลด ${value.toStringAsFixed(0)}%';
    return 'ลด ฿${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/promos'),
      child: Container(
        width: 268,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.foundationRed600, AppColors.foundationRed900],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _headline,
                    style: AppTypography.heading5.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _minSpend > 0 ? 'ขั้นต่ำ ฿${_minSpend.toStringAsFixed(0)}' : _title,
                    style: AppTypography.caption5.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_code != null && _code!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _code!,
                        style: AppTypography.caption5.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
