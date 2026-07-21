import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class VehicleSelectionItem extends StatelessWidget {
  final VehicleEstimation estimation;
  final bool isSelected;
  final VoidCallback onTap;
  final String iconPath;

  const VehicleSelectionItem({
    super.key,
    required this.estimation,
    required this.isSelected,
    required this.onTap,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDisabled = !estimation.available;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        boxShadow: isDisabled
            ? null
            : isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
        color: isDisabled
            ? AppColors.grey100
            : isSelected
            ? AppColors.foundationRed100
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDisabled
              ? AppColors.grey100
              : isSelected
              ? AppColors.primary
              : AppColors.grey100,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(15),
          // IntrinsicHeight lets the Row use CrossAxisAlignment.stretch
          // without needing an unbounded height from the ListView parent.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar for the selected vehicle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 4 : 0,
                  color: AppColors.primary,
                ),

                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Opacity(
                      opacity: isDisabled ? 0.5 : 1.0,
                      child: Row(
                        children: [
                          Image.asset(
                            iconPath,
                            width: 60,
                            height: 40,
                            fit: BoxFit.cover,
                            color: isDisabled ? Colors.grey : null,
                            colorBlendMode:
                                isDisabled ? BlendMode.srcIn : null,
                          ),

                          const SizedBox(width: 16),

                          // Name & subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      estimation.displayName,
                                      style: AppTypography.heading5.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.black87,
                                      ),
                                    ),

                                    if (estimation.surgeMultiplier > 1.0) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.foundationOrange100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${estimation.surgeMultiplier}x',
                                          style:
                                              AppTypography.caption5.copyWith(
                                            color:
                                                AppColors.foundationOrange600,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                if (estimation.surchargeName != null &&
                                    (estimation.pickupSurcharge > 0 ||
                                        estimation.dropoffSurcharge > 0))
                                  Text(
                                    '${estimation.surchargeName}: ฿${(estimation.pickupSurcharge + estimation.dropoffSurcharge).toStringAsFixed(0)}',
                                    style: AppTypography.caption5.copyWith(
                                      color: AppColors.foundationOrange600,
                                    ),
                                  )
                                else
                                  Text(
                                    l10n.baseFareLabel,
                                    style: AppTypography.caption5.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Price column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '฿${estimation.totalFare.toStringAsFixed(0)}',
                                style: AppTypography.heading5.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.black87,
                                ),
                              ),

                              if (estimation.discount > 0 ||
                                  estimation.surgeMultiplier > 1.0)
                                Text(
                                  '฿${estimation.baseFare.toStringAsFixed(0)}',
                                  style: AppTypography.caption4.copyWith(
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),

                              // Discount badge
                              if (estimation.discount > 0) ...[
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ลด ฿${estimation.discount.toStringAsFixed(0)}',
                                    style: AppTypography.caption5.copyWith(
                                      color: const Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
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
