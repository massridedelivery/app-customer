import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/widgets/route_stops.dart';
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
}) => advancePolicyParts(
  l10n,
  freeCancelUntil: freeCancelUntil,
  lateCancelFee: lateCancelFee,
  waitMinutes: waitMinutes,
).join(' · ');

/// The parts of [advancePolicyLine], one per line.
List<String> advancePolicyParts(
  AppLocalizations l10n, {
  String? freeCancelUntil,
  String? lateCancelFee,
  int? waitMinutes,
}) => [
  if (freeCancelUntil != null)
    l10n.scheduledRideFreeCancelUntil(freeCancelUntil),
  if (lateCancelFee != null) l10n.scheduledRideLateFee(lateCancelFee),
  if (waitMinutes != null && waitMinutes > 0)
    l10n.scheduledRideWait('$waitMinutes'),
];

/// "ท่าอากาศยานสุวรรณภูมิ, 999 หนองปรือ …" → the place name and the rest.
(String, String) advanceSplitPlace(String address) {
  final i = address.indexOf(', ');
  if (i <= 0) return (address, '');
  return (address.substring(0, i), address.substring(i + 2));
}

/// The place name for a one-line route; the whole address when its first
/// part is only a house number ("338, ซ. สุขุมวิท 21, …"). A trailing comma
/// left by the geocoder ("338,") is dropped.
String advanceShortPlace(String address) {
  final name = advanceSplitPlace(address).$1;
  final picked = RegExp(r'^[0-9/\-\s]+$').hasMatch(name) ? address : name;
  return picked.replaceFirst(RegExp(r'[,\s]+$'), '');
}

/// "32.4 กม. · ประมาณ 35 นาที"; null when neither is known.
String? advanceTripLine(
  AppLocalizations l10n, {
  double? distanceKm,
  double? durationMin,
}) {
  String km(double v) {
    final s = v >= 10 ? v.round().toString() : v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  final parts = [
    if (distanceKm != null) l10n.advanceTripKm(km(distanceKm)),
    if (durationMin != null) l10n.advanceTripMinutes('${durationMin.round()}'),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Pickup → dropoff with the app's map pins and dotted connector (as
/// [RouteStops]): the place name in bold and the rest of the address on one
/// line, with an optional [footer] (distance · time) under a divider.
class AdvanceRouteSummary extends StatelessWidget {
  const AdvanceRouteSummary({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.footer,
    this.boxed = true,
  });

  final String pickup;
  final String dropoff;
  final String? footer;

  /// False inside another card: just the stops, no border of its own.
  final bool boxed;

  static const _pin = 20.0;

  Widget _icon(Color color) => AppIcons.asset(
    AppAssets.icLocationFill,
    color: color,
    width: _pin,
    height: _pin,
  );

  Widget _stop(String address) {
    final (name, rest) = advanceSplitPlace(address);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.label1.copyWith(fontWeight: FontWeight.w600),
        ),
        if (rest.isNotEmpty)
          Text(
            rest,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops = _stops();
    if (!boxed) return stops;
    return AdvanceCard(
      padding: EdgeInsets.fromLTRB(16, 14, 16, footer == null ? 14 : 0),
      child: stops,
    );
  }

  Widget _stops() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _pin,
              child: Column(
                children: [
                  _icon(AppColors.foundationGreen500),
                  const SizedBox(height: 2),
                  Expanded(
                    child: SizedBox(
                      width: 4,
                      child: CustomPaint(
                        painter: RouteDotsPainter(
                          color: AppColors.foundationGrayscale400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _stop(pickup),
              ),
            ),
          ],
        ),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _icon(AppColors.foundationRed700),
          const SizedBox(width: 12),
          Expanded(child: _stop(dropoff)),
        ],
      ),
      if (footer != null) ...[
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.foundationGrayscale300),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            footer!,
            key: const Key('advanceTripLine'),
            style: AppTypography.caption4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ],
  );
}

/// The yellow "before you book" box: a title and one line per rule.
class AdvancePolicyNotice extends StatelessWidget {
  const AdvancePolicyNotice({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  static const _ink = AppColors.foundationYellow1100;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final text = AppTypography.body3.copyWith(color: _ink, height: 1.5);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.foundationYellow100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.foundationYellow300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppColors.foundationYellow700,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.label3.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: text),
                  Expanded(child: Text(line, style: text)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
