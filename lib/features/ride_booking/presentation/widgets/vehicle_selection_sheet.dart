import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/vehicle_selection_item.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VehicleSelectionSheet extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingControllerProvider);
    final bookingState = bookingAsync.value ?? const BookingState();
    final notifier = ref.read(bookingControllerProvider.notifier);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context)!;

    // No auto-select: the user must explicitly pick a vehicle before the
    // "request ride" button becomes enabled.
    final hasVehicleSelected = bookingState.vehicleTypeId != null;

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
          const SizedBox(height: 12),
          // Grabber
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle List
          SizedBox(
            height: 230, // Approximate height for the list
            child: bookingAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : estimations.isEmpty
                ? Center(child: Text(l10n.calculatingPrice))
                : ListView.builder(
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
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 14),
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.grey[200],
                  ),
                ),
                // Coupon button with active state indicator (ข้อ 6)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: bookingState.appliedPromoCode != null
                          ? const Color(0xFFE8F5E9)
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
                                key: ValueKey(bookingState.appliedPromoCode != null),
                                color: bookingState.appliedPromoCode != null
                                    ? const Color(0xFF2E7D32)
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
                                      ? const Color(0xFF2E7D32)
                                      : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: bookingState.appliedPromoCode != null
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey,
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
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bookingState.appliedPromoCode != null
                          ? 'ส่วนลดคูปอง ${bookingState.appliedPromoCode}'
                          : 'ส่วนลดคูปอง',
                      style: AppTypography.label2.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '-฿${bookingState.promoDiscount.toStringAsFixed(0)}',
                    style: AppTypography.label2.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Request Button
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
                onPressed: hasVehicleSelected ? onRequest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.foundationGreen500, // Green button
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  l10n.requestRideNow,
                  style: AppTypography.heading4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
        return 'พร้อมเพย์';
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
              Text('เลือกวิธีชำระเงิน', style: AppTypography.heading4),
              const SizedBox(height: 8),
              option('CASH', 'เงินสด', Icons.monetization_on),
              option('PROMPTPAY', 'พร้อมเพย์', Icons.qr_code_2_rounded),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
