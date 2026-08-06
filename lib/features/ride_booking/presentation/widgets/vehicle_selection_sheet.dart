import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
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

class VehicleSelectionSheet extends ConsumerStatefulWidget {
  final List<VehicleEstimation> estimations;
  final Function(String id) onVehicleSelected;
  final VoidCallback onRequest;
  final VoidCallback onPromoTap;

  const VehicleSelectionSheet({
    super.key,
    required this.estimations,
    required this.onRequest,
    required this.onPromoTap,
    required this.onVehicleSelected,
  });

  @override
  ConsumerState<VehicleSelectionSheet> createState() =>
      _VehicleSelectionSheetState();
}

class _VehicleSelectionSheetState extends ConsumerState<VehicleSelectionSheet> {
  // Approximate height of one vehicle row; used to size the snap points.
  static const double _rowHeight = 78;
  // Snap index: 0 = 1 row, 1 = 3 rows, 2 = almost full screen. Default = 3 rows.
  int _snapIndex = 1;
  // Live list height while dragging the grabber (null → use the snap point).
  double? _dragHeight;

  List<double> _snapHeights(BuildContext context) => [
    _rowHeight,
    _rowHeight * 3,
    MediaQuery.of(context).size.height * 0.55,
  ];

  void _onDragUpdate(DragUpdateDetails d, List<double> snaps) {
    final base = _dragHeight ?? snaps[_snapIndex];
    // Dragging up (negative dy) grows the list.
    setState(
      () => _dragHeight = (base - d.delta.dy).clamp(snaps.first, snaps.last),
    );
  }

  void _onDragEnd(List<double> snaps) {
    final current = _dragHeight ?? snaps[_snapIndex];
    var nearest = 0;
    var best = double.infinity;
    for (var i = 0; i < snaps.length; i++) {
      final dist = (snaps[i] - current).abs();
      if (dist < best) {
        best = dist;
        nearest = i;
      }
    }
    setState(() {
      _snapIndex = nearest;
      _dragHeight = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingControllerProvider);
    final bookingState = bookingAsync.value ?? const BookingState();
    final notifier = ref.read(bookingControllerProvider.notifier);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context)!;
    final snaps = _snapHeights(context);
    final listHeight = _dragHeight ?? snaps[_snapIndex];

    // No auto-select: the user must explicitly pick a vehicle before the
    // "request ride" button becomes enabled.
    final hasVehicleSelected = bookingState.vehicleTypeId != null;
    VehicleEstimation? selectedEstimation;
    for (final e in widget.estimations) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Draggable grabber: drag up/down to snap the list between 1 row,
          // 3 rows and almost-full-screen.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) => _onDragUpdate(d, snaps),
            onVerticalDragEnd: (_) => _onDragEnd(snaps),
            child: Column(
              children: [
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
              ],
            ),
          ),

          // Vehicle list. Height snaps to 1 / 3 / almost-full rows via the
          // draggable grabber above; it scrolls within whatever height is set,
          // so the payment row and CTA always stay on-screen.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: listHeight),
            child: bookingAsync.isLoading
                ? const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : widget.estimations.isEmpty
                ? SizedBox(
                    height: 120,
                    child: Center(child: Text(l10n.calculatingPrice)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.estimations.length,
                    itemBuilder: (context, index) {
                      final estimation = widget.estimations[index];
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
                      onTap: widget.onPromoTap,
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
                                bookingState.appliedPromoCode ?? l10n.promoLabel,
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

          // Coupon discount summary
          if (bookingState.promoDiscount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_offer_rounded,
                    size: 16,
                    color: _kSuccessFg,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bookingState.appliedPromoCode != null
                          ? '${l10n.couponDiscount} ${bookingState.appliedPromoCode}'
                          : l10n.couponDiscount,
                      style: AppTypography.label2.copyWith(
                        color: _kSuccessFg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '-฿${bookingState.promoDiscount.toStringAsFixed(0)}',
                    style: AppTypography.label2.copyWith(
                      color: _kSuccessFg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Request button. Disabled until a vehicle is picked — and the label
          // says so, so the greyed-out state isn't a dead end. Once selected it
          // confirms the exact vehicle and fare.
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: bottomPadding > 0 ? bottomPadding : 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: hasVehicleSelected ? widget.onRequest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.semanticDisabledBgLow,
                  disabledForegroundColor:
                      AppColors.semanticDisabledFgOnGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  hasVehicleSelected && selectedEstimation != null
                      ? l10n.requestRideWith(
                          selectedEstimation.displayName,
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
