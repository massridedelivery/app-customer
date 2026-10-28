import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
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

/// "คูปองของฉัน": ใช้ได้ / ใช้แล้ว / หมดอายุ.
class VouchersScreen extends ConsumerWidget {
  const VouchersScreen({super.key});

  static const _statuses = ['ACTIVE', 'USED', 'EXPIRED'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return RefetchOnResume(
      onResume: () => ref.invalidate(vouchersProvider),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(l10n.pointsActionVouchers, style: AppTypography.heading4),
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + MediaQuery.paddingOf(context).bottom),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => VoucherCard(voucher: items[i]),
              ),
      ),
    );
  }
}

/// A voucher: title, what it takes off, the code (copyable) and validity.
class VoucherCard extends ConsumerWidget {
  const VoucherCard({super.key, required this.voucher});

  final Voucher voucher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = voucher.status == 'ACTIVE';
    final expires = voucher.expiresAt;
    final soon =
        expires != null &&
        expires.difference(DateTime.now()) < const Duration(days: 3);
    return Container(
      key: Key('voucher-${voucher.code}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            voucher.title,
            style: AppTypography.label1.copyWith(
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          if (voucher.discountText.isNotEmpty)
            Text(
              voucher.discountText,
              style: AppTypography.body3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    voucher.code,
                    style: AppTypography.heading5.copyWith(letterSpacing: 1.5),
                  ),
                ),
              ),
              IconButton(
                key: Key('voucherCopy-${voucher.code}'),
                tooltip: l10n.profileReferralCopy,
                icon: const Icon(Icons.copy_rounded, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: voucher.code));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text(l10n.profileReferralCodeCopied)),
                    );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (voucher.status == 'USED' && voucher.usedAt != null)
            Text(
              l10n.vouchersUsedAt(
                fmtThaiDate(context, voucher.usedAt!),
                serviceLabel(l10n, voucher.usedOrderType),
              ),
              style: AppTypography.caption4.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else if (expires != null)
            Text(
              l10n.rewardsValidUntil(fmtThaiDate(context, expires)),
              key: soon && active ? const Key('voucherExpiringSoon') : null,
              style: AppTypography.caption4.copyWith(
                color: soon && active
                    ? AppColors.semanticErrorFgHigh
                    : AppColors.textSecondary,
              ),
            ),
          if (active) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(l10n.rewardsUseNow),
              ),
            ),
          ],
        ],
      ),
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
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.paddingOf(context).bottom),
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
