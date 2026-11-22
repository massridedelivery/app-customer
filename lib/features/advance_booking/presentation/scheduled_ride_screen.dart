import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/data/support_config_provider.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/advance_booking/domain/advance_config.dart';
import 'package:customer_app/features/advance_booking/domain/advance_refusal.dart';
import 'package:customer_app/features/advance_booking/domain/scheduled_ride.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_common.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_time_sheet.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The customer's rides booked ahead (GET /api/customer/jobs/scheduled),
/// soonest first.
final scheduledRidesProvider = FutureProvider.autoDispose<List<ScheduledRide>>((
  ref,
) async {
  final list = await ref.watch(apiRepositoryProvider).getScheduledJobs();
  return list
      .whereType<Map>()
      .map((m) => ScheduledRide.fromJson(Map<String, dynamic>.from(m)))
      .toList();
});

/// `/scheduled/:id` (Detail variant D): one ride booked ahead — a status
/// banner, the time and route, the driver once one has it, the price, the
/// policy line, "เลื่อนเวลา" and "ยกเลิก". Opened from the bookings tab and
/// the advance booking pushes.
class ScheduledRideScreen extends ConsumerWidget {
  const ScheduledRideScreen({
    super.key,
    required this.jobId,
    this.driverChanged = false,
  });

  final String jobId;

  /// Opened from the advance_driver_changed push: say a new driver is being
  /// found (nothing in the job itself tells).
  final bool driverChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rides = ref.watch(scheduledRidesProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.scheduledRideTitle, style: AppTypography.heading4),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: rides.when(
        loading: () => const Center(child: MassLoadingM(size: 72)),
        error: (e, _) => _Message(
          text: l10n.advanceLoadFailed,
          onRetry: () => ref.invalidate(scheduledRidesProvider),
        ),
        data: (list) {
          final ride = list.where((r) => r.id == jobId).firstOrNull;
          if (ride == null) {
            return _Message(
              key: const Key('scheduledRideNotFound'),
              text: l10n.scheduledRideNotFound,
            );
          }
          return _Body(ride: ride, driverChanged: driverChanged);
        },
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.ride, required this.driverChanged});

  final ScheduledRide ride;
  final bool driverChanged;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  /// reschedules_left from the last PATCH, when the list doesn't carry it.
  int? _movesLeft;
  bool _busy = false;

  ScheduledRide get ride => widget.ride;

  int? get _reschedulesLeft => ride.reschedulesLeft ?? _movesLeft;

  bool get _canReschedule =>
      !ride.hasDriver &&
      !ride.searchStarted &&
      (_reschedulesLeft == null || _reschedulesLeft! > 0);

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = advanceFormatOf(context);
    final now = DateTime.now();
    final at = ride.scheduledAt;
    final freeUntil = ride.freeCancelUntil;
    final secondary = AppTypography.body2.copyWith(
      color: AppColors.textSecondary,
    );
    final banner = widget.driverChanged && !ride.hasDriver
        ? l10n.advanceDriverChangedBanner
        : (ride.phase == 'DISPATCHING' && !ride.hasDriver
              ? l10n.advanceSearchingBanner
              : null);
    final policy = advancePolicyLine(
      l10n,
      freeCancelUntil: freeUntil == null ? null : fmt.when(freeUntil, now: now),
      lateCancelFee: ride.lateCancelFee > 0
          ? fmtBaht(ride.lateCancelFee)
          : null,
      waitMinutes: ride.waitMinutes,
    );
    final payment = switch (ride.paymentMethod) {
      'CASH' => l10n.cashLabel,
      'PROMPTPAY' => l10n.promptPay,
      '' => null,
      final other => other,
    };

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(scheduledRidesProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                if (banner != null) ...[
                  Container(
                    key: const Key('scheduledRideBanner'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.semanticWarningBgLowOnWhite,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      banner,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.semanticWarningFgHigh,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                AdvanceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.advancePickupTimeLabel,
                              style: AppTypography.caption3.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          AdvanceStatusChip(ride: ride),
                        ],
                      ),
                      if (at != null)
                        Text(
                          '${fmt.dayHeading(at, now: now)} ${fmt.clock(at)}',
                          key: const Key('scheduledRidePickupAt'),
                          style: AppTypography.heading3,
                        ),
                      const Divider(height: 20),
                      AdvanceRouteLine(
                        text: ride.pickupAddress,
                        isPickup: true,
                      ),
                      AdvanceRouteLine(
                        text: ride.dropoffAddress,
                        isPickup: false,
                      ),
                      if (ride.flightNumber != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.scheduledRideFlight(ride.flightNumber!),
                          style: secondary,
                        ),
                      ],
                    ],
                  ),
                ),
                if (ride.hasDriver && ride.driverName != null) ...[
                  const SizedBox(height: 12),
                  AdvanceCard(
                    key: const Key('scheduledRideDriver'),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.foundationGrayscale300,
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.driverName!,
                                style: AppTypography.label1.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                [
                                  ride.vehicleDescription,
                                  ride.vehiclePlate,
                                ].whereType<String>().join(' · '),
                                style: AppTypography.caption3.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AdvanceCard(
                  child: Column(
                    children: [
                      _Money(
                        ride.vehicleName != null
                            ? l10n.advanceRideFareLabel(ride.vehicleName!)
                            : l10n.advanceRideFareOnly,
                        ride.rideFare,
                        secondary,
                      ),
                      if (ride.advanceFee > 0) ...[
                        const SizedBox(height: 6),
                        _Money(
                          l10n.advanceFeeLabel,
                          ride.advanceFee,
                          secondary,
                        ),
                      ],
                      const Divider(height: 18),
                      _Money(
                        payment == null
                            ? l10n.advanceTotalLabel
                            : '${l10n.advanceTotalLabel} · $payment',
                        ride.fare,
                        AppTypography.label1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (policy.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    policy,
                    key: const Key('scheduledRidePolicy'),
                    style: AppTypography.caption3.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const Key('scheduledRideReport'),
                    onPressed: _report,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(l10n.advanceReportProblem),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                if (_canReschedule) ...[
                  Expanded(
                    child: _Outlined(
                      key: const Key('scheduledRideReschedule'),
                      label: l10n.advanceReschedule,
                      onPressed: _busy ? null : _reschedule,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _Outlined(
                    key: const Key('scheduledRideCancel'),
                    label: l10n.advanceCancel,
                    danger: true,
                    onPressed: _busy ? null : _cancel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// "แจ้งปัญหางานจองล่วงหน้า": the report form with the advance_booking
  /// topic, or SOS while in-app reports are off.
  void _report() {
    if (!ref.read(supportFlagsProvider).ticketsEnabled) {
      context.push('/sos');
      return;
    }
    context.push(
      Uri(
        path: '/support/report',
        queryParameters: {
          'service': 'ride',
          'ref': ride.id,
          'source': 'scheduled_ride',
          'advance': '1',
        },
      ).toString(),
    );
  }

  /// Move the pickup: the same wheel as booking, then PATCH.
  Future<void> _reschedule() async {
    final l10n = AppLocalizations.of(context)!;
    final fmt = advanceFormatOf(context);
    final config = await _config();
    if (config == null || !mounted) return;
    final left = _reschedulesLeft;
    final at = await showAdvanceTimeSheet(
      context,
      config: config,
      initial: ride.scheduledAt,
      leadMinutes: ride.minLeadMinutes,
      title: l10n.advanceRescheduleTitle,
      buttonLabel: l10n.advanceRescheduleButton,
      header: Text(
        [
          if (left != null) l10n.advanceReschedulesLeft('$left'),
          l10n.advanceRescheduleSamePrice(fmtBaht(ride.fare)),
        ].join(' · '),
        key: const Key('scheduledRideMovesLeft'),
        style: AppTypography.caption3.copyWith(color: AppColors.textSecondary),
      ),
    );
    if (at == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final res = await ref
          .read(apiRepositoryProvider)
          .rescheduleScheduledJob(ride.id, at);
      final movesLeft = res['reschedules_left'];
      if (!mounted) return;
      setState(() => _movesLeft = movesLeft is num ? movesLeft.toInt() : null);
      _snack(
        '${l10n.advanceRescheduled} · ${fmt.when(at, now: DateTime.now())}',
      );
      ref.invalidate(scheduledRidesProvider);
    } catch (e) {
      if (!mounted) return;
      final r = AdvanceRefusal.from(e);
      switch (r?.kind) {
        case AdvanceRefusalKind.cannotReschedule:
          await _offerCancelAndRebook();
        case AdvanceRefusalKind.tooManyReschedules:
          setState(() => _movesLeft = 0);
          _snack(l10n.advanceErrTooManyReschedules);
        case AdvanceRefusalKind.tooSoon || AdvanceRefusalKind.tooFar:
          _snack(l10n.advanceErrTime);
        default:
          _snack(l10n.advanceErrRescheduleFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<AdvanceConfig?> _config() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      ref.invalidate(advanceConfigProvider);
      return await ref.read(advanceConfigProvider.future);
    } catch (_) {
      if (mounted) _snack(l10n.advanceLoadFailed);
      return null;
    }
  }

  /// CANNOT_RESCHEDULE: a driver has it or the search started. Offer cancel
  /// and book again.
  Future<void> _offerCancelAndRebook() async {
    final l10n = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        content: Text(l10n.advanceErrCannotReschedule),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.advanceKeepBooking),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.advanceCancelAndRebook),
          ),
        ],
      ),
    );
    ref.invalidate(scheduledRidesProvider);
    if (go == true && mounted) await _cancel(rebook: true);
  }

  /// Shows what cancelling costs now (cancel-quote): free → the sheet that
  /// says why; a fee → the dialog with the amount. Then cancels.
  Future<void> _cancel({bool rebook = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final api = ref.read(apiRepositoryProvider);
    ScheduledCancelQuote quote;
    try {
      quote = ScheduledCancelQuote.fromJson(
        await api.getScheduledCancelQuote(ride.id),
      );
    } catch (_) {
      if (mounted) _snack(l10n.advanceLoadFailed);
      return;
    }
    if (!mounted) return;
    final free = quote.isFree || quote.fee <= 0;
    final ok = free ? await _confirmFree(quote) : await _confirmFee(quote);
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await api.cancelScheduledJob(ride.id);
      if (!mounted) return;
      _snack(l10n.scheduledRideCancelled);
      ref.invalidate(scheduledRidesProvider);
      if (rebook) {
        context.go('/main');
        context.push('/advance-booking');
      } else {
        context.canPop() ? context.pop() : context.go('/main');
      }
    } catch (_) {
      if (mounted) _snack(l10n.scheduledRideCancelFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Detail variant A: free to cancel, and why.
  Future<bool?> _confirmFree(ScheduledCancelQuote quote) {
    final l10n = AppLocalizations.of(context)!;
    final why = switch (quote.reason) {
      'NO_DRIVER_YET' => l10n.advanceCancelReasonNoDriver,
      'BEFORE_FREE_CANCEL_TIME' => l10n.advanceCancelReasonBeforeFree,
      'DRIVER_LATE' => l10n.advanceCancelReasonDriverLate,
      _ => null,
    };
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.advanceCancelSheetTitle, style: AppTypography.heading4),
              const SizedBox(height: 14),
              Container(
                key: const Key('scheduledRideCancelQuote'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.semanticSuccessBgLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  why == null
                      ? l10n.advanceCancelFree
                      : '${l10n.advanceCancelFree} · $why',
                  style: AppTypography.label2.copyWith(
                    color: AppColors.semanticSuccessFgHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AdvancePrimaryButton(
                key: const Key('scheduledRideCancelConfirm'),
                label: l10n.scheduledRideCancelConfirm,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 10),
              _Outlined(
                label: l10n.advanceKeepBooking,
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Detail variant B: cancelling now has a fee, added to the next ride.
  Future<bool?> _confirmFee(ScheduledCancelQuote quote) {
    final l10n = AppLocalizations.of(context)!;
    final fee = fmtBaht(quote.fee);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.softRedBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.advanceCancelFeeTitle(fee),
                key: const Key('scheduledRideCancelQuote'),
                textAlign: TextAlign.center,
                style: AppTypography.heading4,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.advanceCancelFeeBody,
                textAlign: TextAlign.center,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: AdvancePrimaryButton(
                  key: const Key('scheduledRideCancelConfirm'),
                  label: l10n.advanceCancelWithFee(fee),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: _Outlined(
                  label: l10n.scheduledRideKeep,
                  onPressed: () => Navigator.pop(ctx, false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "รอคนขับ" (amber) / "กำลังหาคนขับ" / "มีคนขับแล้ว" (green).
class AdvanceStatusChip extends StatelessWidget {
  const AdvanceStatusChip({super.key, required this.ride});

  final ScheduledRide ride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (text, bg, fg) = ride.hasDriver
        ? (
            l10n.advanceStatusDriver,
            AppColors.semanticSuccessBgLow,
            AppColors.semanticSuccessFgHigh,
          )
        : ride.phase == 'DISPATCHING'
        ? (
            l10n.advanceStatusSearching,
            AppColors.semanticWarningBgLowOnWhite,
            AppColors.semanticWarningFgHigh,
          )
        : (
            l10n.advanceStatusWaiting,
            AppColors.semanticWarningBgLowOnWhite,
            AppColors.semanticWarningFgHigh,
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTypography.caption4.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Money extends StatelessWidget {
  const _Money(this.label, this.amount, this.style);

  final String label;
  final double amount;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: style)),
      Text('฿${fmtBaht(amount)}', style: style),
    ],
  );
}

class _Outlined extends StatelessWidget {
  const _Outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: danger ? AppColors.secondaryRed : AppColors.textPrimary,
      side: BorderSide(
        color: danger ? AppColors.primary : AppColors.foundationGrayscale400,
      ),
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    child: Text(
      label,
      style: AppTypography.label1.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
    ),
  );
}
