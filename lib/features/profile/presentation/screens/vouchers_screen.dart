import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/core/widgets/refetch_on_resume.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/features/profile/presentation/widgets/use_voucher.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String serviceLabel(AppLocalizations l10n, String? service) =>
    switch (service) {
      'RIDE' => l10n.serviceRide,
      'FOOD' => l10n.serviceFood,
      'MESSENGER' || 'PARCEL' => l10n.serviceMessenger,
      _ => '',
    };

/// "คูปองของฉัน": ใช้ได้ / ใช้แล้ว / หมดอายุ / ยกเลิก.
class VouchersScreen extends ConsumerWidget {
  const VouchersScreen({super.key});

  static const _statuses = ['ACTIVE', 'USED', 'EXPIRED', 'VOIDED'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return RefetchOnResume(
      onResume: () => ref.invalidate(vouchersProvider),
      child: DefaultTabController(
        length: _statuses.length,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              l10n.pointsActionVouchers,
              style: AppTypography.heading4,
            ),
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            bottom: TabBar(
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: l10n.vouchersTabActive),
                Tab(text: l10n.vouchersTabUsed),
                Tab(text: l10n.vouchersTabExpired),
                Tab(text: l10n.vouchersTabVoided),
              ],
            ),
          ),
          body: TabBarView(
            children: [for (final s in _statuses) _VoucherList(status: s)],
          ),
        ),
      ),
    );
  }
}

class _VoucherList extends ConsumerWidget {
  const _VoucherList({required this.status});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vouchers = ref.watch(vouchersProvider(status));
    return vouchers.when(
      loading: () => const Center(child: MassLoadingM(size: 64)),
      error: (e, s) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(vouchersProvider(status)),
          child: Text('${l10n.profileLoadFailed} · ${l10n.retry}'),
        ),
      ),
      data: (items) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(vouchersProvider(status));
          await ref.read(vouchersProvider(status).future);
        },
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 48,
                    color: AppColors.semanticGrayNeutralFgLowOnWhite,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      l10n.vouchersEmpty,
                      key: const Key('vouchersEmpty'),
                      style: AppTypography.label1,
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/rewards'),
                      child: Text(l10n.vouchersGoRedeem),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  32 + MediaQuery.paddingOf(context).bottom,
                ),
                // Expired ones aren't refunded: said once above that list.
                itemCount: items.length + (status == 'EXPIRED' ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (status == 'EXPIRED') {
                    if (i == 0) {
                      return Text(
                        l10n.vouchersExpiredNoRefund,
                        key: const Key('vouchersNoRefundNote'),
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    return VoucherCard(voucher: items[i - 1]);
                  }
                  return VoucherCard(voucher: items[i]);
                },
              ),
      ),
    );
  }
}

/// A voucher, as the same ticket [CouponCard] as every other promo list: the
/// service stub, the code, its own discount_text, the minimum and validity.
/// Active ones can be copied and used now; used / expired / cancelled ones
/// are greyed with what happened to them.
class VoucherCard extends ConsumerWidget {
  const VoucherCard({super.key, required this.voucher});

  final Voucher voucher;

  /// The voucher in the card's terms. Its own discount_text is what it
  /// gives (fixed when it was made); the numbers come from `discount`.
  static CouponCardData dataOf(Voucher v) {
    final d = v.discount;
    final type = d?.type ?? 'FIXED';
    final free = type == 'FREE_DELIVERY';
    final value = d?.value ?? 0;
    String fmt(double x) => x.toStringAsFixed(0);
    return CouponCardData(
      code: v.code,
      title: v.discountText.isNotEmpty ? v.discountText : v.title,
      description: '',
      discountValue: free || value <= 0
          ? ''
          : (type == 'PERCENT' ? '${fmt(value)}%' : '฿${fmt(value)}'),
      freeShipping: free,
      maxDiscount: type == 'PERCENT' || free ? d?.maxDiscount : null,
      minSpend: d?.minSpend ?? 0,
      expiresAt: v.expiresAt,
      scope: free ? PromoScope.food : PromoScope.fromAppliesTo(v.appliesTo),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = voucher.status == 'ACTIVE';
    const muted = TextStyle(fontSize: 12, color: Color(0xFF6B6E7A));
    final Widget? status = switch (voucher.status) {
      'VOIDED' => Text(
        l10n.vouchersVoidedRefund(fmtPoints(voucher.pointsSpent)),
        key: Key('voucherVoided-${voucher.code}'),
        style: muted,
      ),
      'USED' when voucher.usedAt != null => Text(
        l10n.vouchersUsedAt(
          fmtThaiDate(context, voucher.usedAt!),
          serviceLabel(l10n, voucher.usedOrderType),
        ),
        style: muted,
      ),
      _ => null,
    };
    return CouponCard(
      key: Key('voucher-${voucher.code}'),
      data: dataOf(voucher),
      isEnabled: active,
      footer: status,
      action: active
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('voucherCopy-${voucher.code}'),
                  tooltip: l10n.profileReferralCopy,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: voucher.code));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.profileReferralCodeCopied)),
                      );
                  },
                ),
                SizedBox(
                  height: 32,
                  child: FilledButton(
                    key: Key('voucherUse-${voucher.code}'),
                    onPressed: () => useVoucherCode(
                      context,
                      ref,
                      code: voucher.code,
                      appliesTo: voucher.appliesTo,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.rewardsUseNow,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

/// After a redeem: the new voucher, ready to copy or use straight away.
class RedeemSuccessScreen extends ConsumerWidget {
  const RedeemSuccessScreen({super.key, required this.result});

  final RedeemResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final v = result.voucher;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 72,
            color: AppColors.semanticSuccessFgHigh,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.rewardsSuccessTitle,
            textAlign: TextAlign.center,
            style: AppTypography.heading3,
          ),
          const SizedBox(height: 4),
          Text(
            v.discountText.isNotEmpty ? v.discountText : v.title,
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          VoucherCard(voucher: v),
          const SizedBox(height: 12),
          Text(
            l10n.rewardsYouHave(fmtPoints(result.pointsBalance)),
            key: const Key('redeemBalance'),
            textAlign: TextAlign.center,
            style: AppTypography.body3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            key: const Key('redeemSeeVouchers'),
            onPressed: () => context.pushReplacement('/vouchers'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(l10n.rewardsSeeVouchers),
          ),
        ],
      ),
    );
  }
}
