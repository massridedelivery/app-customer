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
              style: AppTypography.caption3.copyWith(
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
          final policy = advancePolicyLine(
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    AdvanceCard(
                      color: AppColors.softRedBg,
                      borderColor: AppColors.softRedBg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.advancePickupTimeLabel,
                            style: AppTypography.label2.copyWith(
                              color: AppColors.secondaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            fmt.when(at, now: now),
                            key: const Key('advanceConfirmWhen'),
                            style: AppTypography.heading2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdvanceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          AdvanceRouteLine(
                            text: home.pickupAddress ?? '',
                            isPickup: true,
                          ),
                          AdvanceRouteLine(
                            text: home.dropoffAddress ?? '',
                            isPickup: false,
                          ),
                        ],
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
                          const Divider(height: 20),
                          _MoneyRow(
                            l10n.advanceTotalLabel,
                            option.fare,
                            style: AppTypography.heading5.copyWith(
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
                        key: const Key('advancePolicyLine'),
                        style: AppTypography.caption3.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _TapRow(
                      key: const Key('advancePaymentRow'),
                      title: l10n.advancePayWith,
                      value: payment == 'CASH'
                          ? l10n.cashLabel
                          : l10n.promptPay,
                      onTap: () => _pickPayment(config, payment),
                    ),
                    const SizedBox(height: 8),
                    _TapRow(
                      key: const Key('advancePromoRow'),
                      title: l10n.advancePromoCode,
                      value: state.promoCode ?? l10n.advancePromoAdd,
                      onTap: () => _editPromo(state.promoCode),
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
                      const SizedBox(height: 6),
                      Text(
                        l10n.advanceFlightHelp('${config.airportWaitMinutes}'),
                        style: AppTypography.caption3.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
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

class _TapRow extends StatelessWidget {
  const _TapRow({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.foundationGrayscale200,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppTypography.body2)),
            Text(
              value,
              style: AppTypography.label2.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}
