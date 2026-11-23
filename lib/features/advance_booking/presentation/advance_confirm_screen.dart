import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/advance_booking/domain/advance_config.dart';
import 'package:customer_app/features/advance_booking/domain/advance_refusal.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_booking_controller.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_common.dart';
import 'package:customer_app/features/advance_booking/presentation/scheduled_ride_screen.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// What the confirm screen hands back to the vehicle list when the time no
/// longer fits (TOO_SOON / TOO_FAR): pick another.
const advanceRetimeResult = 'retime';

/// `/advance-booking/confirm` (Confirm variant A): the time, route, price,
/// one policy line, payment, promo code and — at an airport — the flight.
class AdvanceConfirmScreen extends ConsumerStatefulWidget {
  const AdvanceConfirmScreen({super.key});

  @override
  ConsumerState<AdvanceConfirmScreen> createState() =>
      _AdvanceConfirmScreenState();
}

class _AdvanceConfirmScreenState extends ConsumerState<AdvanceConfirmScreen> {
  final _flight = TextEditingController();
  String? _flightError;

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _submit(AdvanceConfig config) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = ref.read(advanceBookingControllerProvider.notifier);
    ctrl.setFlightNumber(_flight.text);
    setState(() => _flightError = null);
    try {
      final job = await ctrl.submit();
      if (!mounted) return;
      ref.invalidate(scheduledRidesProvider);
      _snack(l10n.advanceBooked);
      final id = '${job['id'] ?? ''}';
      final router = GoRouter.of(context);
      router.go('/main');
      if (id.isNotEmpty) router.push('/scheduled/$id');
    } on AdvanceRefusal catch (r) {
      if (!mounted) return;
      await _handleRefusal(r, config);
    } catch (_) {
      if (mounted) _snack(l10n.advanceErrGeneric);
    }
  }

  Future<void> _handleRefusal(AdvanceRefusal r, AdvanceConfig config) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = ref.read(advanceBookingControllerProvider.notifier);
    switch (r.kind) {
      case AdvanceRefusalKind.disabled:
        ref.invalidate(advanceConfigProvider);
        await showAdvanceClosedDialog(
          context,
          title: r.title ?? config.closedTitle,
          message: r.message ?? config.closedMessage,
        );
        if (mounted) context.go('/main');
      case AdvanceRefusalKind.vehicleNotBookable:
        _snack(l10n.advanceErrVehicleNotBookable);
        ctrl.loadOptions();
        context.pop();
      case AdvanceRefusalKind.tooSoon || AdvanceRefusalKind.tooFar:
        _snack(l10n.advanceErrTime);
        ref.invalidate(advanceConfigProvider);
        context.pop(advanceRetimeResult);
      case AdvanceRefusalKind.tooManyBookings:
        _snack(l10n.advanceErrTooManyBookings);
      case AdvanceRefusalKind.cashNotAllowed:
        ctrl.setPaymentMethod('PROMPTPAY');
        _snack(l10n.advanceErrCashNotAllowed);
      case AdvanceRefusalKind.outstandingFees:
        ctrl.setPaymentMethod('PROMPTPAY');
        _snack(l10n.advanceErrOutstandingFees);
      case AdvanceRefusalKind.flightNumberInvalid:
        setState(() => _flightError = l10n.advanceFlightInvalid);
      case AdvanceRefusalKind.areaNotCovered:
        _snack(l10n.advanceErrArea);
      default:
        _snack(l10n.advanceErrGeneric);
    }
  }

  Future<void> _pickPayment(AdvanceConfig config, String current) async {
    final l10n = AppLocalizations.of(context)!;
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget option(String value, String label, IconData icon) => ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(
            label,
            style: AppTypography.label2.copyWith(fontWeight: FontWeight.bold),
          ),
          trailing: current == value
              ? const Icon(Icons.check_circle, color: AppColors.primary)
              : null,
          onTap: () => Navigator.of(ctx).pop(value),
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(l10n.selectPaymentMethod, style: AppTypography.heading4),
              const SizedBox(height: 8),
              if (config.cashAllowed)
                option('CASH', l10n.cashLabel, Icons.monetization_on),
              option('PROMPTPAY', l10n.promptPay, Icons.qr_code_2_rounded),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (method != null) {
      ref
          .read(advanceBookingControllerProvider.notifier)
          .setPaymentMethod(method);
    }
  }

  Future<void> _editPromo(String? current) async {
    final l10n = AppLocalizations.of(context)!;
    final input = TextEditingController(text: current ?? '');
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(l10n.advancePromoCode, style: AppTypography.heading5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('advancePromoField'),
              controller: input,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.advancePromoNoFee,
              style: AppTypography.body3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: Text(l10n.advancePromoRemove),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(input.text),
            child: Text(l10n.advancePromoApply),
          ),
        ],
      ),
    );
    input.dispose();
    if (code != null) {
      ref.read(advanceBookingControllerProvider.notifier).setPromoCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configAsync = ref.watch(advanceConfigProvider);
    final state = ref.watch(advanceBookingControllerProvider);
    final home = ref.watch(homeControllerProvider);
    final fmt = advanceFormatOf(context);
    final now = DateTime.now();
    final option = state.selected;
    final at = state.scheduledAt;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.advanceConfirmTitle, style: AppTypography.heading4),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: configAsync.when(
        loading: () => const Center(child: MassLoadingM(size: 72)),
        error: (_, _) => Center(child: Text(l10n.advanceLoadFailed)),
        data: (config) {
          if (option == null || at == null) {
            return Center(child: Text(l10n.advanceChooseTime));
          }
          // Cash isn't offered while the admin turned it off.
          final payment = !config.cashAllowed && state.paymentMethod == 'CASH'
              ? 'PROMPTPAY'
              : state.paymentMethod;
          final airport = looksLikeAirport(home.pickupAddress);
          final freeUntil = option.freeCancelUntil;
          final policy = advancePolicyParts(
            l10n,
            freeCancelUntil: freeUntil == null
                ? null
                : fmt.when(freeUntil, now: now),
            lateCancelFee: option.type.lateCancelFee > 0
                ? fmtBaht(option.type.lateCancelFee)
                : null,
            waitMinutes: airport && _flight.text.trim().isNotEmpty
                ? config.airportWaitMinutes
                : config.waitMinutes,
          );
          final label = AppTypography.body2.copyWith(
            color: AppColors.textSecondary,
          );
          return Column(
            children: [
              // Pinned so the time stays in view while the keyboard is up
              // for the flight number.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: AdvanceWhenCard(
                  label: l10n.advancePickupTimeLabel,
                  month: fmt.monthShort(at),
                  day: fmt.dayOfMonth(at),
                  weekday: fmt.weekdayName(at),
                  time: fmt.clockLong(at),
                  fullDate: fmt.fullDate(at),
                  changeLabel: l10n.rideChange,
                  onChange: state.submitting
                      ? null
                      : () => context.pop(advanceRetimeResult),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    AdvanceRouteSummary(
                      pickup: home.pickupAddress ?? '',
                      dropoff: home.dropoffAddress ?? '',
                      footer: advanceTripLine(
                        l10n,
                        distanceKm: state.distanceKm,
                        durationMin: state.durationMin,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdvanceCard(
                      child: Column(
                        children: [
                          _MoneyRow(
                            l10n.advanceRideFareLabel(option.type.displayName),
                            option.rideFare,
                            style: label,
                          ),
                          const SizedBox(height: 8),
                          _MoneyRow(
                            l10n.advanceFeeLabel,
                            option.type.fee,
                            style: label,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: _DashedLine(),
                          ),
                          _MoneyRow(
                            l10n.advanceTotalLabel,
                            option.fare,
                            style: AppTypography.heading5.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  l10n.advancePriceLocked,
                                  style: AppTypography.body3.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (policy.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      AdvancePolicyNotice(
                        key: const Key('advancePolicyLine'),
                        title: l10n.advanceBeforeYouBook,
                        lines: policy,
                      ),
                    ],
                    const SizedBox(height: 12),
                    AdvanceCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          children: [
                            _IconRow(
                              key: const Key('advancePaymentRow'),
                              icon: payment == 'CASH'
                                  ? Icons.payments_outlined
                                  : Icons.qr_code_2_rounded,
                              iconColor: payment == 'CASH'
                                  ? AppColors.foundationGreen700
                                  : AppColors.foundationBlue700,
                              text: payment == 'CASH'
                                  ? l10n.cashLabel
                                  : l10n.promptPay,
                              onTap: () => _pickPayment(config, payment),
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.foundationGrayscale300,
                            ),
                            _IconRow(
                              key: const Key('advancePromoRow'),
                              icon: Icons.local_offer_outlined,
                              iconColor: AppColors.primary,
                              text:
                                  state.promoCode ??
                                  l10n.advancePromoPlaceholder,
                              muted: state.promoCode == null,
                              onTap: () => _editPromo(state.promoCode),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (airport) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.advanceFlightLabel,
                        style: AppTypography.label1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('advanceFlightField'),
                        controller: _flight,
                        textCapitalization: TextCapitalization.characters,
                        // Keep the wait note under the field in view too.
                        scrollPadding: const EdgeInsets.only(bottom: 80),
                        onChanged: (_) => setState(() => _flightError = null),
                        decoration: InputDecoration(
                          hintText: l10n.advanceFlightHint,
                          errorText: _flightError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        cursorColor: AppColors.primary,
                      ),
                      if (config.airportWaitMinutes > config.waitMinutes) ...[
                        const SizedBox(height: 8),
                        Container(
                          key: const Key('advanceFlightWaitNote'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.foundationGreen100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: AppColors.foundationGreen800,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  l10n.advanceFlightWaitNote(
                                    '${config.airportWaitMinutes}',
                                    '${config.waitMinutes}',
                                  ),
                                  style: AppTypography.body3.copyWith(
                                    color: AppColors.foundationGreen800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: AdvancePrimaryButton(
                    key: const Key('advanceConfirmButton'),
                    label: l10n.advanceConfirmButton(fmtBaht(option.fare)),
                    loading: state.submitting,
                    onPressed: () {
                      if (payment != state.paymentMethod) {
                        ref
                            .read(advanceBookingControllerProvider.notifier)
                            .setPaymentMethod(payment);
                      }
                      _submit(config);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.amount, {required this.style});

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

class _IconRow extends StatelessWidget {
  const _IconRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body2.copyWith(
                color: muted ? AppColors.textSecondary : AppColors.textPrimary,
                fontWeight: muted ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}

/// A receipt's dashed rule.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 2,
    width: double.infinity,
    child: CustomPaint(painter: _DashPainter()),
  );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.foundationGrayscale300
      ..strokeWidth = size.height;
    const dash = 6.0, gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + dash).clamp(0, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) => false;
}

/// The pickup time on top of the confirm screen (Confirm B-1): a tear-off
/// calendar day, the time large and the full date under it, and a pen to go
/// back to the time wheel.
class AdvanceWhenCard extends StatelessWidget {
  const AdvanceWhenCard({
    super.key,
    required this.label,
    required this.month,
    required this.day,
    required this.weekday,
    required this.time,
    required this.fullDate,
    required this.changeLabel,
    required this.onChange,
  });

  final String label;
  final String month;
  final int day;
  final String weekday;
  final String time;
  final String fullDate;
  final String changeLabel;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) => AdvanceCard(
    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
    child: Row(
      children: [
        _CalendarTile(month: month, day: day, weekday: weekday),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            key: const Key('advanceConfirmWhen'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.body3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                time,
                style: AppTypography.heading2.copyWith(height: 1.2),
              ),
              Text(
                fullDate,
                style: AppTypography.body3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.foundationGrayscale100,
          shape: const CircleBorder(),
          child: IconButton(
            key: const Key('advanceConfirmChangeTime'),
            tooltip: changeLabel,
            onPressed: onChange,
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A tear-off calendar page: red month strip, the day, the weekday.
class _CalendarTile extends StatelessWidget {
  const _CalendarTile({
    required this.month,
    required this.day,
    required this.weekday,
  });

  final String month;
  final int day;
  final String weekday;

  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Color(0x24000000), blurRadius: 4, offset: Offset(0, 1)),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            month,
            textAlign: TextAlign.center,
            style: AppTypography.label3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          '$day',
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            weekday,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.support1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
