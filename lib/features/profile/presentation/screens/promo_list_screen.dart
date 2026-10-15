import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/data/datasources/promo_remote_data_source.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final promoListProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(promoRemoteDataSourceProvider).getList();
});

class PromoListScreen extends ConsumerStatefulWidget {
  const PromoListScreen({super.key});

  @override
  ConsumerState<PromoListScreen> createState() => _PromoListScreenState();
}

class _PromoListScreenState extends ConsumerState<PromoListScreen> {
  /// Selected scope filter; null = "ทั้งหมด".
  PromoScope? _scope;

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(promoListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.promoMyPromos, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: promosAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MassLoadingM(size: 72),
              const SizedBox(height: 16),
              Text(l10n.promoLoading),
            ],
          ),
        ),
        error: (e, s) {
          debugPrint('PromoList Load Error: $e');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  friendlyError(e, fallback: l10n.errLoadFailed),
                  style: AppTypography.body2,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(promoListProvider),
                  child: Text(l10n.tryAgain),
                ),
              ],
            ),
          );
        },
        data: (raw) {
          final promos = raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (promos.isEmpty) {
            return _empty(l10n.promoNoneNow);
          }

          // Only offer the scopes that actually have promos, and only when
          // there is more than one — a single-scope list needs no filter.
          final scopes = [
            for (final s in PromoScope.values)
              if (promos.any((p) => promoScopeOf(p) == s)) s,
          ];
          final showTabs = scopes.length > 1;
          final scope = showTabs && scopes.contains(_scope) ? _scope : null;
          final visible = scope == null
              ? promos
              : promos.where((p) => promoScopeOf(p) == scope).toList();

          return Column(
            children: [
              if (showTabs)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    children: [
                      _tab(
                        l10n.promoTabEverything,
                        scope == null,
                        () => _select(null),
                      ),
                      for (final s in scopes)
                        _tab(s.tabLabel(l10n), scope == s, () => _select(s)),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(promoListProvider.future),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final promo = visible[index];
                      final promoId = promo['id']?.toString() ?? '';
                      return CouponCard(
                        data: CouponCardData.fromMap(promo),
                        onTap: promoId.isEmpty
                            ? null
                            : () => context.push('/promos/$promoId'),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _select(PromoScope? scope) => setState(() => _scope = scope);

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE5E0DD),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption4.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
