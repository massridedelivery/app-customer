import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/live_ride/domain/models/driver_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Payment summary shown right after a ride completes, before the review
/// screen. Lays out the fare breakdown (fare, tolls/waiting, discount), lets
/// the rider add a tip, then continues to the rating screen. The chosen tip is
/// forwarded to the rating screen (which submits it) via the `tip` query param.
class PaymentSummaryScreen extends ConsumerStatefulWidget {
  final String jobId;
  final DriverProfileModel? driverProfile;

  const PaymentSummaryScreen({
    super.key,
    required this.jobId,
    this.driverProfile,
  });

  @override
  ConsumerState<PaymentSummaryScreen> createState() =>
      _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends ConsumerState<PaymentSummaryScreen> {
  int? _selectedTip;

  static const _tipOptions = [10, 20, 50];

  String _formatBaht(double amount) {
    // Never force-round on the client (SCRUM-89: fares are whole baht from BE,
    // but a driver-entered toll can still carry satang). Show satang only when
    // the amount actually has them.
    final sign = amount < 0 ? '-' : '';
    final abs = amount.abs();
    final intPart = abs.floor();
    final digits = intPart.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    final hasSatang = abs != abs.roundToDouble();
    final satang = hasSatang ? (abs - intPart).toStringAsFixed(2).substring(1) : '';
    return '$sign฿$buffer$satang';
  }

  String _paymentMethodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return 'เงินสด';
      case 'PROMPTPAY':
        return 'พร้อมเพย์';
      case 'COD':
        return 'เก็บเงินปลายทาง';
      default:
        return method.isEmpty ? 'ไม่ระบุ' : method;
    }
  }

  IconData _paymentMethodIcon(String method) {
    switch (method.toUpperCase()) {
      case 'PROMPTPAY':
        return Icons.qr_code_2;
      default:
        return Icons.payments_outlined;
    }
  }

  void _continueToReview() {
    final tipQuery = _selectedTip != null ? '?tip=$_selectedTip' : '';
    context.pushReplacement(
      '/rating/${widget.jobId}$tipQuery',
      extra: widget.driverProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.driverProfile;
    final method = (profile?.paymentMethod ?? '').toUpperCase();
    // Cash / cash-on-delivery has no channel to deduct a tip from, so the tip
    // selector only makes sense for card / PromptPay.
    final canTip = method != 'CASH' && method != 'COD';
    final fare = profile?.fare ?? 0;
    final discount = profile?.discount ?? 0;
    final tollFee = profile?.tollFee ?? 0;
    final waitingFee = profile?.waitingFee ?? 0;
    final tip = (canTip ? (_selectedTip ?? 0) : 0).toDouble();
    final total = fare + tollFee + waitingFee - discount + tip;

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'สรุปการชำระเงิน',
          style: AppTypography.heading4.copyWith(color: AppColors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fare breakdown
            _buildSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สรุปค่าโดยสาร', style: AppTypography.label2),
                  const SizedBox(height: 16),
                  _amountRow('ค่าโดยสาร', _formatBaht(fare)),
                  if (tollFee > 0) ...[
                    const SizedBox(height: 12),
                    _amountRow('ค่าทางด่วน', _formatBaht(tollFee)),
                  ],
                  if (waitingFee > 0) ...[
                    const SizedBox(height: 12),
                    _amountRow('ค่ารอคอย', _formatBaht(waitingFee)),
                  ],
                  if (discount > 0) ...[
                    const SizedBox(height: 12),
                    _amountRow(
                      'ส่วนลด',
                      '-${_formatBaht(discount)}',
                      valueColor: AppColors.primary,
                    ),
                  ],
                  if (tip > 0) ...[
                    const SizedBox(height: 12),
                    _amountRow('ทิปให้คนขับ', _formatBaht(tip)),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ยอดชำระทั้งหมด',
                        style: AppTypography.label1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatBaht(total),
                        style: AppTypography.heading4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Payment method
            _buildSection(
              child: Row(
                children: [
                  Icon(
                    _paymentMethodIcon(profile?.paymentMethod ?? ''),
                    color: AppColors.semanticGrayNeutralFgHigh,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text('วิธีชำระเงิน', style: AppTypography.label2),
                  const Spacer(),
                  Text(
                    _paymentMethodLabel(profile?.paymentMethod ?? ''),
                    style: AppTypography.label2.copyWith(
                      color: AppColors.semanticGrayNeutralFgHigh,
                    ),
                  ),
                ],
              ),
            ),

            if (canTip) ...[
            const SizedBox(height: 12),

            // Tip
            _buildSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.volunteer_activism,
                        color: AppColors.foundationGreen500,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('ให้ทิปคนขับ (ไม่บังคับ)', style: AppTypography.label2),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ทิปจะถูกหักจากช่องทางชำระเงินที่คุณเลือก',
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.semanticGrayNeutralFgLowOnWhite,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: _tipOptions.map((option) {
                      final selected = _selectedTip == option;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedTip = selected ? null : option;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.foundationGreen500
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.foundationGreen500
                                      : AppColors.grey300,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+฿$option',
                                  style: AppTypography.label2.copyWith(
                                    color: selected
                                        ? AppColors.white
                                        : AppColors.semanticGrayNeutralFgHigh,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Pinned action bar at the bottom of the screen.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _continueToReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ยืนยันและให้คะแนน',
                    style: AppTypography.label1.copyWith(color: AppColors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.label2.copyWith(
            color: AppColors.semanticGrayNeutralFgLowOnWhite,
          ),
        ),
        Text(
          value,
          style: AppTypography.label2.copyWith(
            color: valueColor ?? AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
