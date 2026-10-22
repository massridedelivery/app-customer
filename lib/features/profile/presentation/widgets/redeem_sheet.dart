import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/services/idempotency.dart';
import 'package:customer_app/features/profile/data/datasources/loyalty_remote_data_source.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "ใช้ X คะแนน แลก Y?" → ยืนยัน. On success goes to the success screen;
/// on a refusal says why (the server's own text) and refreshes what changed.
Future<void> confirmRedeem(
  BuildContext context,
  WidgetRef ref, {
  required Reward reward,
  required int balance,
}) async {
  final result = await showModalBottomSheet<RedeemResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RedeemSheet(reward: reward, balance: balance),
  );
  if (result == null || !context.mounted) return;
  refreshLoyalty(ref);
  context.push('/rewards/success', extra: result);
}

class _RedeemSheet extends ConsumerStatefulWidget {
  const _RedeemSheet({required this.reward, required this.balance});

  final Reward reward;
  final int balance;

  @override
  ConsumerState<_RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends ConsumerState<_RedeemSheet> {
  // One key per confirm: a retry after a dropped connection resends it, so
  // the server replays the first voucher instead of spending twice.
  String? _key;
  bool _busy = false;
  ApiError? _retryable;

  Future<void> _redeem() async {
    if (_busy) return;
    _key ??= generateIdempotencyKey();
    setState(() {
      _busy = true;
      _retryable = null;
    });
    try {
      final json = await ref
          .read(loyaltyRemoteDataSourceProvider)
          .redeemReward(widget.reward.id, idempotencyKey: _key!);
      if (!mounted) return;
      Navigator.of(context).pop(RedeemResult.fromJson(json));
    } catch (e) {
      if (!mounted) return;
      final err = ApiError.from(e);
      if (err.isNetwork || err.code == 'INTERNAL_ERROR' || err.code == null) {
        // Not refused, just didn't get through: retry with the same key.
        setState(() {
          _busy = false;
          _retryable = err;
        });
        return;
      }
      switch (err.code) {
        case 'REWARD_OUT_OF_STOCK' ||
            'REWARD_NOT_ACTIVE' ||
            'REWARD_ENDED' ||
            'REWARD_NOT_FOUND' ||
            'POINTS_DISABLED':
          ref.invalidate(rewardsProvider);
        case 'POINTS_INSUFFICIENT':
          ref.invalidate(rewardsProvider);
          ref.invalidate(loyaltySummaryProvider);
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(err.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = widget.reward;
    final left = widget.balance - r.pointsCost;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.rewardsConfirm(fmtPoints(r.pointsCost), r.discountText),
              key: const Key('redeemConfirmText'),
              style: AppTypography.heading5,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.rewardsConfirmLeft(fmtPoints(left < 0 ? 0 : left)),
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_retryable != null) ...[
              const SizedBox(height: 12),
              Text(
                _retryable!.message,
                key: const Key('redeemError'),
                style: AppTypography.body3.copyWith(
                  color: AppColors.semanticErrorFgHigh,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('redeemConfirm'),
              onPressed: _busy ? null : _redeem,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _retryable != null
                          ? l10n.retry
                          : l10n.rewardsConfirmButton,
                      style: AppTypography.label1.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
