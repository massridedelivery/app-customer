import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/features/profile/presentation/widgets/tier_widgets.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The dark-red "MASS POINTS" card (design B4): tier badge, balance, the
/// customer's name with the balance's baht value, and the Mass "M" as a faint
/// watermark. Shared by the profile page and คะแนนของฉัน so the two always
/// look the same; [onTap] null (on คะแนนของฉัน itself) also drops the
/// "ดูคะแนน ›" link.
class MassPointsCard extends StatelessWidget {
  const MassPointsCard({
    super.key,
    required this.summary,
    this.name = '',
    this.onTap,
  });

  final LoyaltySummary summary;

  /// Shown before the baht value; empty while the profile hasn't loaded.
  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final worth = l10n.pointsWorth(fmtBaht(summary.balanceBaht));
    const radius = BorderRadius.all(Radius.circular(20));
    final faint = AppTypography.caption5.copyWith(
      color: Colors.white.withValues(alpha: 0.85),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E0B24), Color(0xFFB80E2E), Color(0xFFD5143A)],
          stops: [0, 0.6, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x47280A14),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: 0,
                  bottom: 0,
                  child: Image.asset(
                    AppAssets.pointsMark,
                    width: 190,
                    color: Colors.white.withValues(alpha: 0.09),
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'MASS POINTS',
                            style: AppTypography.label3.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 2,
                            ),
                          ),
                          if (summary.tier != null) ...[
                            const SizedBox(width: 8),
                            TierBadge(
                              name: summary.tier!.displayName(
                                Localizations.localeOf(context).languageCode,
                              ),
                              color: summary.tier!.color,
                              iconUrl: summary.tier!.iconUrl,
                              onDark: true,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            fmtPoints(summary.totalPoints),
                            key: const Key('pointsBalance'),
                            style: AppTypography.heading2.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            ' ${l10n.pointsUnit}',
                            style: AppTypography.body2.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.isEmpty ? worth : '$name · $worth',
                              style: faint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onTap != null) ...[
                            Text(l10n.pointsViewDetail, style: faint),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
