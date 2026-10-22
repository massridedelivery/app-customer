import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_quote.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// 🪙 ใช้คะแนน — the switch under the promo row: on uses all the points this
/// trip allows, off none. Shows the balance, the most usable here and (when
/// on) how many are used. Numbers come from the
/// selected vehicle's estimate; nothing is assumed in the app.
class RidePointsRow extends StatelessWidget {
  const RidePointsRow({
    super.key,
    required this.quote,
    required this.on,
    required this.onToggle,
    required this.onLogin,
  });

  final RidePointsQuote quote;

  /// On = all the points this trip allows (there's no partial amount).
  final bool on;
  final ValueChanged<bool> onToggle;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reason = quote.reasonUnavailable;
    final unavailable = switch (reason) {
      'NO_POINTS' => l10n.ridePointsNoPoints,
      'BELOW_MIN' => l10n.ridePointsBelowMin(fmtPoints(quote.minRedeem)),
      'NOTHING_TO_PAY' => l10n.ridePointsNothingToPay,
      'GUEST' => l10n.ridePointsGuest,
      _ => null,
    };
    final usable = reason == null;
    final using = on && usable && quote.usedPoints > 0;
    final muted = AppColors.textSecondary;
    return InkWell(
      key: const Key('ridePointsRow'),
      onTap: reason == 'GUEST' ? onLogin : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('🪙', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ridePointsUse,
                    style: AppTypography.label2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: usable ? AppColors.textPrimary : muted,
                    ),
                  ),
                  Text(
                    unavailable ??
                        l10n.ridePointsAvailable(
                          fmtPoints(quote.balance),
                          fmtPoints(quote.maxUsablePoints),
                        ),
                    key: const Key('ridePointsInfo'),
                    style: AppTypography.caption4.copyWith(
                      color: reason == 'GUEST' ? AppColors.primary : muted,
                    ),
                  ),
                  if (using)
                    Text(
                      l10n.ridePointsUsing(
                        fmtPoints(quote.usedPoints),
                        fmtBaht(quote.discount),
                      ),
                      key: const Key('ridePointsUsing'),
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticSuccessFgHigh,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Switch.adaptive(
              key: const Key('ridePointsSwitch'),
              value: on && usable,
              activeTrackColor: AppColors.primary,
              onChanged: usable ? onToggle : null,
            ),
          ],
        ),
      ),
    );
  }
}
