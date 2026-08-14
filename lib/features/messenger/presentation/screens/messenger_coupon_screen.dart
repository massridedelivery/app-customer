import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coupon picker for the messenger booking. Lets the user either type a code or
/// tap one from their active promotions (GET /api/customer/promo/list). Returns
/// the chosen code string via `Navigator.pop`, or null if dismissed.
class MessengerCouponScreen extends ConsumerStatefulWidget {
  final String? initialCode;
  const MessengerCouponScreen({super.key, this.initialCode});

  @override
  ConsumerState<MessengerCouponScreen> createState() =>
      _MessengerCouponScreenState();
}

class _MessengerCouponScreenState extends ConsumerState<MessengerCouponScreen> {
  late final TextEditingController _manual = TextEditingController(
    text: widget.initialCode ?? '',
  );

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  void _apply(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(promoListProvider);

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'เลือกโค้ดส่วนลด',
          style: AppTypography.heading4.copyWith(color: AppColors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Manual entry — same shared pill as the ride "ใช้คูปอง" flow.
          CouponManualEntry(
            controller: _manual,
            onApply: _apply,
            applyLabel: 'ใช้โค้ด',
            hint: 'กรอกโค้ดส่วนลด',
          ),
          Expanded(
            child: promosAsync.when(
              loading: () => const Center(child: MassLoadingM(size: 72)),
              error: (error, stack) => Center(
                child: Text(
                  'โหลดโค้ดส่วนลดไม่สำเร็จ',
                  style: AppTypography.label2.copyWith(
                    color: AppColors.semanticGrayNeutralFgLowOnWhite,
                  ),
                ),
              ),
              data: (raw) {
                final promos = raw
                    .map(
                      (e) => e is Map<String, dynamic>
                          ? e
                          : Map<String, dynamic>.from(e as Map),
                    )
                    .toList();
                if (promos.isEmpty) {
                  return Center(
                    child: Text(
                      'ยังไม่มีโค้ดส่วนลด',
                      style: AppTypography.label2.copyWith(
                        color: AppColors.semanticGrayNeutralFgLowOnWhite,
                      ),
                    ),
                  );
                }
                // Same list flow as the ride "ใช้คูปอง" screen: a header, the
                // shared ticket CouponCard with an apply/cancel toggle, and a
                // selected highlight for the currently-applied code.
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: promos.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 12),
                        child: Text(
                          'คูปองส่วนลดที่มี',
                          style: AppTypography.label1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    if (index == promos.length + 1) {
                      return const SizedBox(height: 20);
                    }
                    final data = CouponCardData.fromMap(promos[index - 1]);
                    final selected = data.code.isNotEmpty &&
                        data.code == widget.initialCode;
                    return CouponCard(
                      data: data,
                      isSelected: selected,
                      onApply: () => _apply(data.code),
                      onCancel: () => Navigator.of(context).pop(''),
                      applyLabel: 'ใช้โค้ด',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

