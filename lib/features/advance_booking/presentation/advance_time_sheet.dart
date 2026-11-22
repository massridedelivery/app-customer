import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/advance_booking/domain/advance_config.dart';
import 'package:customer_app/features/advance_booking/domain/advance_slots.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_common.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Opens the pickup time wheel (PickerWheel variant C): day | hour | minute,
/// times that can't be booked greyed out. Returns the chosen UTC instant, or
/// null when dismissed. Also used to move a booking ([buttonLabel]).
Future<DateTime?> showAdvanceTimeSheet(
  BuildContext context, {
  required AdvanceConfig config,
  DateTime? initial,
  AdvanceVehicleType? vehicle,
  int? leadMinutes,
  String Function(String when)? buttonLabel,
  String? title,
  Widget? header,
  DateTime? now,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => AdvanceTimeSheet(
      config: config,
      initial: initial,
      vehicle: vehicle,
      leadMinutes: leadMinutes,
      buttonLabel: buttonLabel,
      title: title,
      header: header,
      now: now,
    ),
  );
}

class AdvanceTimeSheet extends StatefulWidget {
  const AdvanceTimeSheet({
    super.key,
    required this.config,
    this.initial,
    this.vehicle,
    this.leadMinutes,
    this.buttonLabel,
    this.title,
    this.header,
    this.now,
  });

  final AdvanceConfig config;
  final DateTime? initial;

  /// The chosen vehicle type: a note shows when the time is too soon for it.
  final AdvanceVehicleType? vehicle;

  /// Overrides the config's earliest lead (a booking's own policy).
  final int? leadMinutes;
  final String Function(String when)? buttonLabel;
  final String? title;

  /// Extra content between the title and the wheel (e.g. moves left).
  final Widget? header;
  final DateTime? now;

  @override
  State<AdvanceTimeSheet> createState() => _AdvanceTimeSheetState();
}

class _AdvanceTimeSheetState extends State<AdvanceTimeSheet> {
  static const _itemExtent = 44.0;

  late final DateTime _now;
  late final AdvanceSlots _slots;
  late final List<DateTime> _days;
  late DateTime _selected;
  late final FixedExtentScrollController _day;
  late final FixedExtentScrollController _hour;
  late final FixedExtentScrollController _minute;

  @override
  void initState() {
    super.initState();
    _now = (widget.now ?? DateTime.now()).toUtc();
    _slots = AdvanceSlots(
      now: _now,
      minLeadMinutes: widget.leadMinutes ?? widget.config.minLeadMinutes,
      maxDays: widget.config.maxDays,
      slotMinutes: widget.config.slotMinutes,
    );
    _days = _slots.days;
    _selected = _slots.clamp(widget.initial ?? _slots.earliest);
    final wall = AdvanceSlots.toBangkok(_selected);
    _day = FixedExtentScrollController(initialItem: _dayIndex(wall));
    _hour = FixedExtentScrollController(initialItem: wall.hour);
    _minute = FixedExtentScrollController(
      initialItem: _slots.minutes.indexOf(wall.minute).clamp(0, 59),
    );
  }

  @override
  void dispose() {
    _day.dispose();
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  int _dayIndex(DateTime wall) {
    final i = _days.indexWhere(
      (d) => d.year == wall.year && d.month == wall.month && d.day == wall.day,
    );
    return i < 0 ? 0 : i;
  }

  /// A wheel moved: take the reading, snap it into range, and turn any wheel
  /// that now reads differently.
  void _changed() {
    if (_days.isEmpty) return;
    final d = _days[_day.selectedItem.clamp(0, _days.length - 1)];
    final h = _hour.selectedItem.clamp(0, 23);
    final m = _slots
        .minutes[_minute.selectedItem.clamp(0, _slots.minutes.length - 1)];
    final picked = _slots.at(d, h, m);
    final snapped = _slots.isBookable(picked) ? picked : _slots.clamp(picked);
    setState(() => _selected = snapped);
    if (snapped != picked) {
      final wall = AdvanceSlots.toBangkok(snapped);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jump(_day, _dayIndex(wall));
        _jump(_hour, wall.hour);
        _jump(_minute, _slots.minutes.indexOf(wall.minute));
      });
    }
  }

  void _jump(FixedExtentScrollController c, int item) {
    if (c.hasClients && c.selectedItem != item) {
      c.animateToItem(
        item,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = advanceFormatOf(context);
    final selectedWall = AdvanceSlots.toBangkok(_selected);
    final selectedDay = _days.isEmpty
        ? DateTime.utc(selectedWall.year, selectedWall.month, selectedWall.day)
        : _days[_dayIndex(selectedWall)];

    final vehicle = widget.vehicle;
    final vehicleEarliest = vehicle == null
        ? null
        : _slots.earliestFor(_now, vehicle.minLeadMinutes);
    final tooSoonForVehicle =
        vehicleEarliest != null && _selected.isBefore(vehicleEarliest);
    final when = fmt.when(_selected, now: _now);

    Widget item(String text, bool enabled) => Center(
      child: Text(
        text,
        style: AppTypography.heading5.copyWith(
          fontWeight: FontWeight.w500,
          color: enabled
              ? AppColors.textPrimary
              : AppColors.foundationGrayscale400,
          decoration: enabled ? null : TextDecoration.lineThrough,
          decorationColor: AppColors.foundationGrayscale400,
        ),
      ),
    );

    Widget wheel(
      FixedExtentScrollController controller,
      int count,
      Widget Function(int) builder,
    ) => CupertinoPicker.builder(
      scrollController: controller,
      itemExtent: _itemExtent,
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: (_) => _changed(),
      childCount: count,
      itemBuilder: (_, i) => builder(i),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title ?? l10n.advancePickTime,
              style: AppTypography.heading4,
            ),
            if (widget.header != null) ...[
              const SizedBox(height: 8),
              widget.header!,
            ],
            const SizedBox(height: 12),
            Container(
              key: const Key('advanceRangeLine'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.foundationGrayscale200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.advanceRangeLine(
                        fmt.when(_slots.earliest, now: _now),
                        fmt.relativeDay(_slots.latest, now: _now),
                        '${_slots.slotMinutes}',
                      ),
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _itemExtent * 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        height: _itemExtent,
                        decoration: BoxDecoration(
                          color: AppColors.foundationGrayscale200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 22,
                        child: wheel(
                          _day,
                          _days.length,
                          (i) => item(
                            fmt.relativeDay(
                              AdvanceSlots.fromBangkok(_days[i]),
                              now: _now,
                            ),
                            true,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: wheel(
                          _hour,
                          24,
                          (h) => item(
                            h.toString().padLeft(2, '0'),
                            _slots.hourHasSlot(selectedDay, h),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: wheel(
                          _minute,
                          _slots.minutes.length,
                          (i) => item(
                            _slots.minutes[i].toString().padLeft(2, '0'),
                            _slots.isBookable(
                              _slots.at(
                                selectedDay,
                                selectedWall.hour,
                                _slots.minutes[i],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (tooSoonForVehicle) ...[
              const SizedBox(height: 8),
              Container(
                key: const Key('advanceVehicleLeadNote'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.semanticWarningBgLowOnWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.advanceVehicleLeadNote(
                    vehicle!.displayName,
                    advanceLeadText(l10n, vehicle.minLeadMinutes),
                    fmt.when(vehicleEarliest, now: _now),
                  ),
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.semanticWarningFgHigh,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            AdvancePrimaryButton(
              key: const Key('advanceTimeConfirm'),
              label:
                  widget.buttonLabel?.call(when) ??
                  l10n.advanceBookAtButton(when),
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}
