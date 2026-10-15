import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/vehicle_name_th.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/vehicle_selection_item.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Success accent for the applied-coupon state, sourced from the design system.
const Color _kSuccessFg = AppColors.semanticSuccessFgHigh;
const Color _kSuccessBg = AppColors.semanticSuccessBgLow;

class VehicleSelectionSheet extends ConsumerWidget {
  // Provided by the parent DraggableScrollableSheet; the list scrolls with it,
  // so dragging the list resizes/snaps the sheet.
  final ScrollController scrollController;
  final List<VehicleEstimation> estimations;
  final Function(String id) onVehicleSelected;
  final VoidCallback onRequest;
  final VoidCallback onPromoTap;

  /// Pickup or dropoff is still unset, so no estimate can be requested.
  final bool isMissingLocation;

  /// Opens the pickup/dropoff picker (shown when [isMissingLocation]).
  final VoidCallback? onPickLocation;

  /// Re-runs the fare estimate after it failed.
  final VoidCallback? onRetryEstimate;

  const VehicleSelectionSheet({
    super.key,
    required this.scrollController,
    required this.estimations,
    required this.onRequest,
    required this.onPromoTap,
    required this.onVehicleSelected,
    this.isMissingLocation = false,
    this.onPickLocation,
    this.onRetryEstimate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingControllerProvider);
    final bookingState = bookingAsync.value ?? const BookingState();
    final notifier = ref.read(bookingControllerProvider.notifier);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context)!;

    // No auto-select: the user must explicitly pick a vehicle before the
    // "request ride" button becomes enabled.
    final hasVehicleSelected = bookingState.vehicleTypeId != null;
    VehicleEstimation? selectedEstimation;
    for (final e in estimations) {
      if (e.vehicleTypeId == bookingState.vehicleTypeId) {
        selectedEstimation = e;
        break;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Grabber. Drag anywhere on the sheet/list to resize; the parent
          // DraggableScrollableSheet snaps to 1 row / 3 rows / almost full.
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.semanticGrayNeutralBgDarkgray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle list — fills the draggable sheet and scrolls with its
          // ScrollController, so dragging it drives the sheet's snap. The
          // loading/empty states are still scrollable so the drag keeps working.
          Expanded(
            child: bookingAsync.isLoading
                ? ListView(
                    controller: scrollController,
                    children: const [
                      SizedBox(
                        height: 160,
                        child: Center(child: MassLoadingM(size: 56)),
                      ),
                    ],
                  )
                : estimations.isEmpty
                ? ListView(
                    controller: scrollController,
                    children: [
                      SizedBox(
                        height: 160,
                        child: _EmptyEstimate(
                          // Without a pickup/dropoff no estimate is ever sent,
                          // and a failed one never retries on its own — so
                          // only say "calculating" while one can still land.
                          message: isMissingLocation
                              ? l10n.selectPickupFirst
                              : bookingAsync.hasError
                              ? l10n.fareEstimateFailed
                              : l10n.calculatingPrice,
                          actionLabel: isMissingLocation
                              ? l10n.choosePickupAction
                              : bookingAsync.hasError
                              ? l10n.retry
                              : null,
                          onAction: isMissingLocation
                              ? onPickLocation
                              : onRetryEstimate,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: estimations.length,
                    itemBuilder: (context, index) {
                      final estimation = estimations[index];
                      final isSelected =
                          bookingState.vehicleTypeId ==
                          estimation.vehicleTypeId;

                      return VehicleSelectionItem(
                        estimation: estimation,
                        isSelected: isSelected,
                        onTap: () {
                          notifier.setVehicleType(estimation.vehicleTypeId);
                        },
                        iconPath: notifier.getVehicleIcon(
                          estimation.vehicleTypeName,
                        ),
                      );
                    },
                  ),
          ),

          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.semanticGrayNeutralBorderLightgray,
          ),

          // Payment and Promo section
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showPaymentPicker(
                      context,
                      notifier,
                      bookingState.paymentMethod,
                      l10n,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            bookingState.paymentMethod == 'PROMPTPAY'
                                ? Icons.qr_code_2_rounded
                                : Icons.monetization_on,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _paymentLabel(bookingState.paymentMethod, l10n),
                            style: AppTypography.label2.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 14, bottom: 14),
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.semanticGrayNeutralBorderLightgray,
                  ),
                ),
                // Coupon button, with an applied-coupon success state.
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: bookingState.appliedPromoCode != null
                          ? _kSuccessBg
                          : Colors.transparent,
                    ),
                    child: InkWell(
                      onTap: onPromoTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Icon(
                                bookingState.appliedPromoCode != null
                                    ? Icons.check_circle
                                    : Icons.confirmation_number_outlined,
                                key: ValueKey(
                                  bookingState.appliedPromoCode != null,
                                ),
                                color: bookingState.appliedPromoCode != null
                                    ? _kSuccessFg
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bookingState.appliedPromoCode ??
                                    l10n.promoLabel,
                                style: AppTypography.label2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: bookingState.appliedPromoCode != null
                                      ? _kSuccessFg
                                      : AppColors.semanticGrayNeutralFgHigh,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: bookingState.appliedPromoCode != null
                                  ? _kSuccessFg
                                  : AppColors.semanticGrayNeutralFgLowOnWhite,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Coupon summary. The amount is what the fare estimate actually took
          // off (the selected vehicle's `discount`), not the validate call's
          // figure — otherwise the chip promised a discount the price didn't
          // show. A code the estimate didn't apply gets a neutral note instead.
          if (bookingState.appliedPromoCode != null &&
              !bookingAsync.isLoading &&
              estimations.isNotEmpty)
            _CouponSummary(
              code: bookingState.appliedPromoCode!,
              discount: (selectedEstimation ?? estimations.first).discount,
            ),

          // Request button. Disabled until a vehicle is picked — and the label
          // says so, so the greyed-out state isn't a dead end. Once selected it
          // confirms the exact vehicle and fare.
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: bottomPadding > 0 ? bottomPadding : 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: hasVehicleSelected ? onRequest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.semanticDisabledBgLow,
                  disabledForegroundColor: AppColors.semanticDisabledFgOnGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  hasVehicleSelected && selectedEstimation != null
                      ? l10n.requestRideWith(
                          vehicleName(
                            selectedEstimation.displayName,
                            vehicleTypeName: selectedEstimation.vehicleTypeName,
                            languageCode:
                                Localizations.localeOf(context).languageCode,
                          ),
                          selectedEstimation.totalFare.toStringAsFixed(0),
                        )
                      : l10n.selectVehicleFirst,
                  style: AppTypography.heading4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _paymentLabel(String method, AppLocalizations l10n) {
    switch (method) {
      case 'PROMPTPAY':
        return l10n.promptPay;
      case 'CASH':
        return l10n.cashLabel;
      default:
        return method;
    }
  }

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

/// Placeholder for the vehicle list when there are no estimations yet, with
/// an optional action (pick a location / retry).
class _EmptyEstimate extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyEstimate({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, textAlign: TextAlign.center),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}

/// The applied-coupon chip under the vehicle list: green with the amount when
/// the estimate discounted the fare, a neutral note when it didn't.
class _CouponSummary extends StatelessWidget {
  final String code;
  final double discount;

  const _CouponSummary({required this.code, required this.discount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final applied = discount > 0;
    final fg = applied ? _kSuccessFg : AppColors.textSecondary;
    final style = AppTypography.label2.copyWith(
      color: fg,
      fontWeight: FontWeight.bold,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  ? '${l10n.couponDiscount} $code'
                  : l10n.couponNotAppliedToFare(code),
              style: style,
            ),
          ),
          if (applied) Text('-฿${discount.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}
