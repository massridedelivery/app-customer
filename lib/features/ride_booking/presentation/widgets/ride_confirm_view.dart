import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/vehicle_name_th.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_quote.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/ride_points_widgets.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Color _kSuccessFg = AppColors.semanticSuccessFgHigh;
const Color _kSuccessBg = AppColors.semanticSuccessBgLow;

/// Step 2 of booking ("ยืนยันการเดินทาง"): the chosen vehicle, payment
/// method, promo code, the points switch, the price breakdown and the request
/// button. Step 1 is the vehicle list on the map.
class RideConfirmView extends ConsumerWidget {
  const RideConfirmView({
    super.key,
    required this.onBack,
    required this.onRequest,
    required this.onPromoTap,
    this.onPromoRemove,
    this.onPointsToggle,
    required this.onPointsLogin,
  });

  /// Back to the vehicle list (also "เปลี่ยน" on the vehicle card).
  final VoidCallback onBack;
  final VoidCallback onRequest;
  final VoidCallback onPromoTap;

  /// Drops the applied code; null hides ✕.
  final VoidCallback? onPromoRemove;

  /// On = all the points this trip allows, off = none. Null hides the row.
  final ValueChanged<bool>? onPointsToggle;
  final VoidCallback onPointsLogin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bookingAsync = ref.watch(bookingControllerProvider);
    final state = bookingAsync.value ?? const BookingState();
    final notifier = ref.read(bookingControllerProvider.notifier);
    VehicleEstimation? selected;
    for (final e in state.estimations) {
      if (e.vehicleTypeId == state.vehicleTypeId) selected = e;
    }
    final points = selected?.points;
    final showPoints =
        onPointsToggle != null &&
        points != null &&
        !points.hidden &&
        !state.pointsDisabled;
    final paidByPoints =
        selected != null &&
        selected.amountToPay != null &&
        selected.payable <= 0;
    final code = state.appliedPromoCode;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Material(
      key: const Key('rideConfirmView'),
      color: AppColors.semanticGrayNeutralBgWhite,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header: back to step 1.
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('rideConfirmBack'),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.rideConfirmTitle,
                              style: AppTypography.heading4,
                            ),
                            Text(
                              l10n.rideConfirmStep,
                              style: AppTypography.caption4.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (selected != null)
                        _Card(
                          child: Row(
                            children: [
                              Image.asset(
                                notifier.getVehicleIcon(
                                  selected.vehicleTypeName,
                                ),
                                width: 56,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  vehicleName(
                                    selected.displayName,
                                    vehicleTypeName: selected.vehicleTypeName,
                                    languageCode: languageCode,
                                  ),
                                  style: AppTypography.label1,
                                ),
                              ),
                              TextButton(
                                key: const Key('rideConfirmChange'),
                                onPressed: onBack,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                                child: Text(l10n.rideChange),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      _Card(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            // Payment method, or nothing to pay at all.
                            if (paidByPoints)
                              _Row(
                                key: const Key('ridePaidByPoints'),
                                leading: const Text(
                                  '🪙',
                                  style: TextStyle(fontSize: 18),
                                ),
                                title: l10n.ridePaidByPoints,
                                titleColor: _kSuccessFg,
                              )
                            else
                              _Row(
                                key: const Key('ridePaymentRow'),
                                leading: Icon(
                                  state.paymentMethod == 'PROMPTPAY'
                                      ? Icons.qr_code_2_rounded
                                      : Icons.monetization_on,
                                  color: AppColors.primary,
                                ),
                                title: l10n.ridePaymentMethodRow,
                                value: _paymentLabel(state.paymentMethod, l10n),
                                onTap: () => _showPaymentPicker(
                                  context,
                                  notifier,
                                  state.paymentMethod,
                                  l10n,
                                ),
                              ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _Row(
                              key: const Key('ridePromoRow'),
                              leading: Icon(
                                code != null
                                    ? Icons.check_circle
                                    : Icons.confirmation_number_outlined,
                                color: code != null
                                    ? _kSuccessFg
                                    : AppColors.primary,
                              ),
                              title: l10n.ridePromoRow,
                              value: code ?? l10n.promoLabel,
                              valueColor: code != null ? _kSuccessFg : null,
                              onTap: onPromoTap,
                              trailing: code != null && onPromoRemove != null
                                  ? IconButton(
                                      key: const Key('ridePromoRemove'),
                                      tooltip: l10n.couponRemove,
                                      onPressed: onPromoRemove,
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: _kSuccessFg,
                                      ),
                                    )
                                  : null,
                            ),
                            if (code != null &&
                                selected != null &&
                                !bookingAsync.isLoading)
                              _CouponNote(
                                code: code,
                                discount: selected.discount,
                                promo: selected.promo,
                                reason: state.promoRejectReason,
                                onRemove: onPromoRemove,
                              ),
                            if (showPoints) ...[
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              RidePointsRow(
                                quote: points,
                                on: state.usePoints,
                                onToggle: onPointsToggle!,
                                onLogin: onPointsLogin,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (selected != null)
                        RidePriceSummary(estimation: selected, code: code),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      key: const Key('rideConfirmRequest'),
                      onPressed: selected == null || bookingAsync.isLoading
                          ? null
                          : onRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.semanticDisabledBgLow,
                        disabledForegroundColor:
                            AppColors.semanticDisabledFgOnGray,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        l10n.rideRequestPrice(
                          fmtBaht(selected?.payable ?? 0),
                        ),
                        style: AppTypography.heading4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (bookingAsync.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black12,
                  child: Center(child: MassLoadingM(size: 64)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String method, AppLocalizations l10n) =>
      switch (method) {
        'PROMPTPAY' => l10n.promptPay,
        'CASH' => l10n.cashLabel,
        _ => method,
      };

  void _showPaymentPicker(
    BuildContext context,
    BookingController notifier,
    String current,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget option(String value, String label, IconData icon) {
          final selected = current == value;
          return ListTile(
            leading: Icon(icon, color: AppColors.primary),
            title: Text(
              label,
              style: AppTypography.label2.copyWith(fontWeight: FontWeight.bold),
            ),
            trailing: selected
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () {
              notifier.setPaymentMethod(value);
              Navigator.of(ctx).pop();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(l10n.selectPaymentMethod, style: AppTypography.heading4),
              const SizedBox(height: 8),
              option('CASH', l10n.cashLabel, Icons.monetization_on),
              option('PROMPTPAY', l10n.promptPay, Icons.qr_code_2_rounded),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(12)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// One tappable line of the payment card: icon, title, value, chevron.
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.leading,
    required this.title,
    this.value,
    this.titleColor,
    this.valueColor,
    this.onTap,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? value;
  final Color? titleColor;
  final Color? valueColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.label2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
              if (value != null)
                Flexible(
                  child: Text(
                    value!,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label2.copyWith(
                      color: valueColor ?? AppColors.textSecondary,
                      fontWeight: valueColor != null ? FontWeight.bold : null,
                    ),
                  ),
                ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Under the promo row: what the code took off (named by its kind), or why
/// it didn't apply, with "เอาโค้ดออก".
class _CouponNote extends StatelessWidget {
  const _CouponNote({
    required this.code,
    required this.discount,
    this.promo,
    this.reason,
    this.onRemove,
  });

  final String code;
  final double discount;
  final RidePromoQuote? promo;
  final String? reason;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final applied = discount > 0;
    final fg = applied ? _kSuccessFg : AppColors.textSecondary;
    // A friend's code / voucher is named by its kind ("โค้ดเพื่อน −฿50");
    // its refusal comes with a Thai reason from the estimate itself.
    final label = promo?.label;
    final why = promo?.errorCode != null ? promo?.error : reason;
    final style = AppTypography.label3.copyWith(
      color: fg,
      fontWeight: FontWeight.bold,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: applied ? _kSuccessBg : AppColors.semanticGrayNeutralBgMidgray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            applied ? Icons.local_offer_rounded : Icons.info_outline_rounded,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              applied
                  ? (label ?? '${l10n.couponDiscount} $code')
                  : why != null
                  ? l10n.couponNotAppliedReason(code, why)
                  : l10n.couponNotAppliedToFare(code),
              style: style,
            ),
          ),
          if (applied) Text('-฿${fmtBaht(discount)}', style: style),
          if (!applied && onRemove != null)
            TextButton(
              key: const Key('ridePromoRemoveLink'),
              onPressed: onRemove,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.couponRemove),
            ),
        ],
      ),
    );
  }
}
