import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/data/datasources/referral_remote_data_source.dart';
import 'package:customer_app/features/profile/data/welcome_promo_store.dart';
import 'package:customer_app/features/profile/domain/models/referral_info.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// The user's referral programme state. autoDispose: every visit reads fresh
/// stats (and the backend creates the user's code on this GET).
final referralInfoProvider = FutureProvider.autoDispose<ReferralInfo>((
  ref,
) async {
  final json = await ref.watch(referralRemoteDataSourceProvider).getInfo();
  final info = ReferralInfo.fromJson(json);
  // A referred newcomer who hasn't ordered yet: keep their welcome code ready
  // to pre-fill on the first ride / parcel.
  if (info.welcomePromoPending) {
    await ref.read(welcomePromoStoreProvider).save(info.referredByWelcomeCode!);
  }
  return info;
});

/// "แนะนำเพื่อน": share your code, see how many friends signed up / ordered,
/// and (as a new customer) enter a friend's code for a welcome discount.
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(referralInfoProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.profileReferralTitle, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: referralAsync.when(
        loading: () => const Center(child: MassLoadingM(size: 72)),
        error: (e, s) => Center(
          child: Text(l10n.profileLoadFailed, style: AppTypography.body2),
        ),
        data: (info) => !info.enabled
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.referralErrDisabled,
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(referralInfoProvider),
                child: _ReferralBody(info: info),
              ),
      ),
    );
  }
}

class _ReferralBody extends StatelessWidget {
  const _ReferralBody({required this.info});

  final ReferralInfo info;

  String _baht(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friendValue = _baht(info.friendRewardValue);
    final code = info.code ?? '';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (info.welcomePromoPending) ...[
          _Notice(
            key: const Key('referralWelcomeReminder'),
            icon: Icons.card_giftcard_rounded,
            text: l10n.referralUseWelcomeCode(info.referredByWelcomeCode!),
          ),
          const SizedBox(height: 16),
        ],
        // Hero: what each side gets, straight from the backend.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.accentRedDeep],
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.group_add_rounded,
                size: 56,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.profileReferralHeadline,
                style: AppTypography.heading3.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.referralRewardSummary(
                  friendValue,
                  info.referrerRewardPoints,
                ),
                style: AppTypography.body2.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Code + copy + share.
        _Card(
          child: Column(
            children: [
              Text(
                l10n.profileReferralYourCode,
                style: AppTypography.caption4.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                code,
                key: const Key('referralCode'),
                style: AppTypography.heading2.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: code.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.profileReferralCodeCopied),
                                ),
                              );
                            },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(l10n.profileReferralCopy),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: AppTypography.label2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('referralShare'),
                      onPressed: code.isEmpty
                          ? null
                          : () => SharePlus.instance.share(
                              ShareParams(
                                text: l10n.referralShareText(code, friendValue),
                              ),
                            ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(l10n.profileReferralShare),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: AppTypography.label2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Results.
        Row(
          children: [
            _Stat(
              label: l10n.referralStatInvited,
              value: '${info.stats.totalReferrals}',
            ),
            const SizedBox(width: 10),
            _Stat(
              label: l10n.referralStatCompleted,
              value: '${info.stats.completedCount}',
            ),
            const SizedBox(width: 10),
            _Stat(
              label: l10n.referralStatPoints,
              value: '${info.stats.totalRewardPoints}',
            ),
          ],
        ),
        if (info.stats.pendingCount > 0) ...[
          const SizedBox(height: 10),
          Text(
            l10n.referralStatPending(
              info.stats.pendingCount,
              info.stats.pendingRewardPoints,
            ),
            key: const Key('referralPending'),
            textAlign: TextAlign.center,
            style: AppTypography.caption4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        // Entering a friend's code: new customers only, until apply_before.
        if (info.canApplyCode && !info.wasReferred) ...[
          const SizedBox(height: 20),
          _Card(
            key: const Key('referralApplyCard'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.profileReferralHaveCode, style: AppTypography.heading5),
                const SizedBox(height: 4),
                Text(
                  l10n.referralApplySubtitle(friendValue),
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (info.applyBefore != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.referralApplyBefore(
                      AppDates.of(context).dateTime(info.applyBefore!.toLocal()),
                    ),
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const _ApplyReferralField(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
      ),
      child: child,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.semanticSuccessBgLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.semanticSuccessFgHigh),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.label2.copyWith(
                color: AppColors.semanticSuccessFgHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.heading3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption5.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Thai/English message for a `POST /referral/apply` error `code`.
String referralApplyError(AppLocalizations l10n, String? code) {
  switch (code) {
    case 'referral_invalid_code':
      return l10n.referralErrInvalidCode;
    case 'referral_self':
      return l10n.referralErrSelf;
    case 'referral_already_used':
      return l10n.referralErrAlreadyUsed;
    case 'referral_not_new_customer':
      return l10n.referralErrNotNewCustomer;
    case 'referral_window_closed':
      return l10n.referralErrWindowClosed;
    case 'referral_code_full':
      return l10n.referralErrCodeFull;
    case 'referral_expired':
      return l10n.referralErrExpired;
    case 'referral_disabled':
      return l10n.referralErrDisabled;
    default:
      return l10n.profileReferralApplyInvalid;
  }
}

class _ApplyReferralField extends ConsumerStatefulWidget {
  const _ApplyReferralField();

  @override
  ConsumerState<_ApplyReferralField> createState() =>
      _ApplyReferralFieldState();
}

class _ApplyReferralFieldState extends ConsumerState<_ApplyReferralField> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('referralApplyInput'),
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            style: AppTypography.body1,
            decoration: InputDecoration(
              hintText: l10n.profileReferralCodeHint,
              hintStyle: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          key: const Key('referralApplyButton'),
          onPressed: _loading ? null : _apply,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            textStyle: AppTypography.label2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.profileReferralApply),
        ),
      ],
    );
  }

  Future<void> _apply() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final res = await ref
          .read(referralRemoteDataSourceProvider)
          .applyCode(code);
      final promo = res['welcome_promo'];
      final promoCode = promo is Map ? promo['code']?.toString() : null;
      final value = promo is Map ? promo['discount_value'] : null;
      if (promoCode != null && promoCode.isNotEmpty) {
        // Pre-filled on the first ride / parcel order.
        await ref.read(welcomePromoStoreProvider).save(promoCode);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            promoCode != null
                ? l10n.referralApplySuccessPromo(
                    promoCode,
                    value is num ? value.toStringAsFixed(0) : '$value',
                  )
                : l10n.profileReferralApplySuccess,
          ),
        ),
      );
      _ctrl.clear();
      ref.invalidate(referralInfoProvider);
    } on DioException catch (e) {
      final data = e.response?.data;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            referralApplyError(
              l10n,
              data is Map ? data['code']?.toString() : null,
            ),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileReferralApplyInvalid)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
