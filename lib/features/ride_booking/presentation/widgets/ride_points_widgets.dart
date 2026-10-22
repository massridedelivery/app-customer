import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_quote.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🪙 ใช้คะแนน — the switch under the promo row, with the balance, the most
/// usable on this trip and (when on) how many are used. Numbers come from the
/// selected vehicle's estimate; nothing is assumed in the app.
class RidePointsRow extends StatelessWidget {
  const RidePointsRow({
    super.key,
    required this.quote,
    required this.on,
    required this.onToggle,
    required this.onEdit,
    required this.onLogin,
  });

  final RidePointsQuote quote;
  final bool on;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        TextButton(
                          key: const Key('ridePointsEdit'),
                          onPressed: onEdit,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(0, 28),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(l10n.ridePointsEdit),
                        ),
                      ],
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

/// "แก้จำนวน": a slider and a number field from `min_redeem` to
/// `max_usable_points`, the baht it takes off, and "ใช้ทั้งหมด".
Future<int?> showPointsAmountSheet(
  BuildContext context, {
  required RidePointsQuote quote,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PointsAmountSheet(quote: quote),
  );
}

class _PointsAmountSheet extends StatefulWidget {
  const _PointsAmountSheet({required this.quote});

  final RidePointsQuote quote;

  @override
  State<_PointsAmountSheet> createState() => _PointsAmountSheetState();
}

class _PointsAmountSheetState extends State<_PointsAmountSheet> {
  late final int _min = widget.quote.minRedeem.clamp(1, _max);
  late final int _max = widget.quote.maxUsablePoints < 1
      ? 1
      : widget.quote.maxUsablePoints;
  late int _value = (widget.quote.usedPoints > 0
          ? widget.quote.usedPoints
          : _max)
      .clamp(_min, _max);
  late final _field = TextEditingController(text: '$_value');

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _set(int v, {bool fromField = false}) {
    setState(() => _value = v);
    if (!fromField) _field.text = '$v';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // A typed number above the maximum is sent as typed: the backend says
    // why it can't, and the screen brings it down to the maximum.
    final typed = int.tryParse(_field.text) ?? _value;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.ridePointsSheetTitle, style: AppTypography.heading5),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('ridePointsField'),
                    controller: _field,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      suffixText: l10n.pointsUnit,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (s) {
                      final v = int.tryParse(s);
                      if (v != null) _set(v.clamp(0, 1 << 30), fromField: true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  key: const Key('ridePointsUseAll'),
                  onPressed: () => _set(_max),
                  child: Text(l10n.ridePointsUseAll),
                ),
              ],
            ),
            if (_max > _min)
              Slider(
                key: const Key('ridePointsSlider'),
                value: _value.clamp(_min, _max).toDouble(),
                min: _min.toDouble(),
                max: _max.toDouble(),
                divisions: (_max - _min).clamp(1, 1000),
                activeColor: AppColors.primary,
                label: fmtPoints(_value),
                onChanged: (v) => _set(v.round()),
              ),
            Text(
              l10n.ridePointsSheetDiscount(
                fmtBaht(typed * widget.quote.bahtPerPoint),
              ),
              key: const Key('ridePointsSheetDiscount'),
              style: AppTypography.label1.copyWith(
                color: AppColors.semanticSuccessFgHigh,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('ridePointsConfirm'),
              onPressed: typed >= 1 ? () => Navigator.of(context).pop(typed) : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(l10n.rewardsConfirmButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fare, the code's discount, the points used, and what's left to pay —
/// shown once something comes off the fare.
class RidePriceSummary extends StatelessWidget {
  const RidePriceSummary({
    super.key,
    required this.estimation,
    required this.code,
  });

  final VehicleEstimation estimation;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = estimation;
    final gross = e.grossFare ?? e.totalFare + e.discount;
    final promo = e.promo;
    final points = e.points;
    final pointsUsed = points?.usedPoints ?? 0;
    final promoLabel = promo?.label ?? l10n.couponDiscount;
    Widget line(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (bold ? AppTypography.label1 : AppTypography.body3)
                  .copyWith(
                    color: bold
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: (bold ? AppTypography.heading5 : AppTypography.body3)
                .copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
    return Container(
      key: const Key('ridePriceSummary'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          line(l10n.rideFare, '฿${fmtBaht(gross)}'),
          if (e.discount > 0)
            line(
              code == null ? promoLabel : '$promoLabel ($code)',
              '−฿${fmtBaht(e.discount)}',
            ),
          if (pointsUsed > 0)
            line(
              l10n.ridePointsLine(fmtPoints(pointsUsed)),
              '−฿${fmtBaht(points!.discount)}',
            ),
          const Divider(height: 12),
          line(l10n.rideAmountToPay, '฿${fmtBaht(e.payable)}', bold: true),
          if (e.payable <= 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.ridePaidByPointsNote,
              key: const Key('ridePaidByPointsNote'),
              style: AppTypography.caption5.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
