import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/core/widgets/route_stops.dart';
import 'package:customer_app/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Payment summary shown right after a parcel is delivered, before the review
/// screen — mirrors the ride flow (live_ride → payment_summary → rating).
final _summaryOrderProvider = FutureProvider.autoDispose
    .family<MessengerOrder, String>((ref, id) async {
      return ref.watch(messengerRepositoryProvider).getOrder(id);
    });

class MessengerPaymentSummaryScreen extends ConsumerWidget {
  final String orderId;

  const MessengerPaymentSummaryScreen({super.key, required this.orderId});

  String _paymentLabel(String method) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(_summaryOrderProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/main'),
        ),
        title: Text(
          'สรุปการชำระเงิน',
          style: AppTypography.heading4.copyWith(color: AppColors.black),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: MassLoadingM(size: 72)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'โหลดข้อมูลไม่สำเร็จ',
              style: AppTypography.body2,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (order) => _content(context, order),
      ),
    );
  }

  Widget _content(BuildContext context, MessengerOrder order) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('เส้นทางจัดส่ง', style: AppTypography.label2),
                      const SizedBox(height: 14),
                      RouteStops(
                        showLabels: false,
                        pickupLabel: 'จุดรับพัสดุ',
                        dropoffLabel: 'จุดส่งพัสดุ',
                        pickupAddress: order.pickupAddress,
                        dropoffAddress: order.dropoffAddress,
                        addressStyle: AppTypography.body2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ข้อมูลพัสดุ', style: AppTypography.label2),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.inventory_2_outlined,
                        'ขนาด ${order.packageSizeTier.isNotEmpty ? order.packageSizeTier : '-'} '
                            '• ${order.packageWeightKg.toStringAsFixed(1)} กก.',
                      ),
                      if (order.recipientName.isNotEmpty ||
                          order.recipientPhone.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _infoRow(
                          Icons.person_outline,
                          [
                            order.recipientName,
                            order.recipientPhone,
                          ].where((s) => s.isNotEmpty).join(' • '),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('สรุปค่าจัดส่ง', style: AppTypography.label2),
                      const SizedBox(height: 16),
                      _amountRow(
                        'ค่าส่ง (${order.distanceKm.toStringAsFixed(1)} กม.)',
                        '฿${order.fare.toStringAsFixed(0)}',
                      ),
                      if (order.discount > 0) ...[
                        const SizedBox(height: 12),
                        _amountRow(
                          'ส่วนลด',
                          '-฿${order.discount.toStringAsFixed(0)}',
                          valueColor: AppColors.primary,
                        ),
                      ],
                      if (order.isCod && order.codAmount > 0) ...[
                        const SizedBox(height: 12),
                        _amountRow(
                          'เก็บเงินปลายทาง (COD)',
                          '฿${order.codAmount.toStringAsFixed(0)}',
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            // Recipient-pays: the fee is collected at the door,
                            // so the sender's amount_due is 0 — label it as
                            // "ชำระปลายทาง" and still show the ฿ amount, not ฿0.
                            order.isRecipientPays
                                ? 'ชำระปลายทาง (${_paymentLabel(order.paymentMethod)})'
                                : 'ยอดชำระ (${_paymentLabel(order.paymentMethod)})',
                            style: AppTypography.label1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '฿${order.deliveryFee.toStringAsFixed(0)}',
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    context.pushReplacement('/messenger/review/$orderId'),
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
    );
  }

  Widget _section({required Widget child}) {
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

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.semanticGrayNeutralFgMidOnWhite),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTypography.body2)),
      ],
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
}
