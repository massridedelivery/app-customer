import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/advance_booking/domain/advance_config.dart';
import 'package:customer_app/features/advance_booking/domain/advance_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// GET /api/customer/advance-booking/config — read fresh each time a screen
/// that needs it opens (the admin can switch it at any moment).
final advanceConfigProvider = FutureProvider.autoDispose<AdvanceConfig>((
  ref,
) async {
  final json = await ref.watch(apiRepositoryProvider).getAdvanceConfig();
  return AdvanceConfig.fromJson(json);
});

/// Bangkok-time labels in the app's language.
AdvanceFormat advanceFormatOf(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return AdvanceFormat(
    Localizations.localeOf(context).languageCode,
    today: l10n.advanceToday,
    tomorrow: l10n.advanceTomorrow,
  );
}

/// "2 ชั่วโมง" / "45 นาที" for a lead time.
String advanceLeadText(AppLocalizations l10n, int minutes) =>
    minutes >= 60 && minutes % 60 == 0
    ? l10n.advanceLeadHours('${minutes ~/ 60}')
    : l10n.advanceLeadMinutes('$minutes');

/// The admin's "advance booking is closed" dialog (Main variant E). The
/// texts come from the config or the 422 body — never hard-coded.
Future<void> showAdvanceClosedDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.softRedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            if (title.isNotEmpty)
              Text(
                title,
                key: const Key('advanceClosedTitle'),
                textAlign: TextAlign.center,
                style: AppTypography.heading4,
              ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                key: const Key('advanceClosedMessage'),
                textAlign: TextAlign.center,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AdvancePrimaryButton(
                label: l10n.advanceGotIt,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The red pill button the advance booking screens end on.
class AdvancePrimaryButton extends StatelessWidget {
  const AdvancePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.foundationGrayscale300,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: AppTypography.heading5.copyWith(color: Colors.white),
            ),
    );
  }
}

/// A white rounded card with a hairline border.
class AdvanceCard extends StatelessWidget {
  const AdvanceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borderColor = AppColors.foundationGrayscale300,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor),
    ),
    child: child,
  );
}

/// A pickup / dropoff line with its coloured dot.
class AdvanceRouteLine extends StatelessWidget {
  const AdvanceRouteLine({
    super.key,
    required this.text,
    required this.isPickup,
    this.onTap,
  });

  final String text;
  final bool isPickup;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isPickup ? AppColors.success : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTypography.body2)),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

/// The confirm screen's policy line: "ยกเลิกฟรีถึง 05:30 · หลังจากนั้นเสีย
/// ฿60 ถ้ามีคนขับรับงานแล้ว · คนขับรอได้ 10 นาที". Parts that are unknown are
/// left out.
String advancePolicyLine(
  AppLocalizations l10n, {
  String? freeCancelUntil,
  String? lateCancelFee,
  int? waitMinutes,
}) {
  return [
    if (freeCancelUntil != null)
      l10n.scheduledRideFreeCancelUntil(freeCancelUntil),
    if (lateCancelFee != null) l10n.scheduledRideLateFee(lateCancelFee),
    if (waitMinutes != null && waitMinutes > 0)
      l10n.scheduledRideWait('$waitMinutes'),
  ].join(' · ');
}
