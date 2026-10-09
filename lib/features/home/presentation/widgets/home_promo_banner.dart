import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/promo_style.dart';
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: promos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, i) => _PromoCard(promo: promos[i]),
              ),
            ),
            // Bottom gap kept inside the banner so it collapses with it when
            // there are no promos (no dangling space above the next section).
            const SizedBox(height: 26),
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

  String get _id => (promo['id'] ?? '').toString();

  num get _minSpend {
    final v = promo['min_order'] ?? promo['min_spend'] ?? 0;
    return v is num ? v : num.tryParse(v.toString()) ?? 0;
  }

  /// Headline like "ลด ฿100" / "ลด 20%" / "ส่งฟรี", derived from discount_type.
  String get _headline => promoHeadlineOf(promo, fallback: _title);

  @override
  Widget build(BuildContext context) {
    // Card color: admin-set `color` if present, else auto by discount_type
    // (fixed→red, percentage→orange, free_shipping→green). Tapping opens detail.
    final Color base = promoColorOf(promo);
    final Color dark = Color.lerp(base, Colors.black, 0.28)!;
    final bool hasCode = _code != null && _code!.isNotEmpty;
    return GestureDetector(
      onTap: () =>
          context.push(_id.isNotEmpty ? '/promos/$_id' : '/promos'),
      child: Container(
        width: 224,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, dark],
          ),
        ),
        child: Stack(
          children: [
            // Faint oversized "%" watermark.
            Positioned(
              right: -10,
              bottom: -30,
              child: Text(
                '%',
                style: TextStyle(
                  fontSize: 84,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headline,
                        style: AppTypography.heading4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _minSpend > 0
                            ? '$_title · ขั้นต่ำ ฿${_minSpend.toStringAsFixed(0)}'
                            : _title,
                        style: AppTypography.caption5.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (hasCode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Text(
                            _code!,
                            style: AppTypography.caption5.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
