import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/promo_card.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/providers/discover_promos_provider.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_promo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RideCouponScreen extends ConsumerStatefulWidget {
  const RideCouponScreen({super.key});

  @override
  ConsumerState<RideCouponScreen> createState() => _RideCouponScreenState();
}

class _RideCouponScreenState extends ConsumerState<RideCouponScreen> {
  final _manualController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo(String code) async {
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await ref
          .read(bookingControllerProvider.notifier)
          .validatePromo(code);

      if (isValid) {
        // Pop and return the validated promo code to the booking screen.
        // The booking screen will then call estimateFare with the promo,
        // preventing bookingControllerProvider from going into loading state
        // while the coupon screen is still mounted (which caused the
        // RenderBox layout crash).
        if (mounted) {
          Navigator.pop(context, code);
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid Promo Code';
        });
      }
    } catch (e) {
      final errorMsg = e.toString();
      setState(() {
        if (errorMsg.startsWith('Exception: ')) {
          _errorMessage = errorMsg.substring('Exception: '.length);
        } else {
          _errorMessage = errorMsg;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _cancelPromo() {
    // Pop with empty string to signal cancellation.
    // The booking screen will re-estimate without a promo code.
    Navigator.pop(context, '');
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingControllerProvider).value;
    final appliedPromoCode = bookingState?.appliedPromoCode;
    final promosAsync = ref.watch(discoverPromosProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'เลือกคูปองส่วนลด',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                // SECTION 1: Manual promo code input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _errorMessage != null
                                ? AppColors.error
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(
                              Icons.local_offer_outlined,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _manualController,
                                onChanged: (val) {
                                  if (_errorMessage != null) {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  }
                                },
                                decoration: const InputDecoration(
                                  hintText: 'กรอกรหัสคูปองด้วยตนเอง',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(7),
                                  bottomRight: Radius.circular(7),
                                ),
                              ),
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        final code = _manualController.text
                                            .trim();
                                        _applyPromo(code);
                                      },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'ใช้งาน',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.caption5.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // SECTION 2: List of promotions (Scrollable)
                Expanded(
                  child: promosAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        'ไม่สามารถโหลดคูปองได้: $err',
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    data: (promos) {
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.refresh(discoverPromosProvider.future),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            0.0,
                            16.0,
                            16.0,
                          ),
                          itemCount: promos.isEmpty ? 2 : promos.length + 2,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 16.0,
                                  bottom: 12.0,
                                ),
                                child: Text(
                                  'คูปองส่วนลดที่มี',
                                  style: AppTypography.label1.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            if (index ==
                                (promos.isEmpty ? 1 : promos.length + 1)) {
                              return const SizedBox(height: 20);
                            }

                            final promoIndex = index - 1;
                            if (promos.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 64.0,
                                ),
                                child: Center(
                                  child: Text(
                                    'ไม่มีคูปองที่สามารถใช้งานได้ในขณะนี้',
                                    style: AppTypography.label2.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final promo = promos[promoIndex];
                            final isSelected = appliedPromoCode == promo.code;
                            return _RidePromoCard(
                              promo: promo,
                              isSelected: isSelected,
                              onApplyTap: () => _applyPromo(promo.code),
                              onCancelTap: _cancelPromo,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
        ),
      ),
    );
  }
}

class _RidePromoCard extends StatelessWidget {
  final RidePromo promo;
  final bool isSelected;
  final VoidCallback onApplyTap;
  final VoidCallback onCancelTap;

  const _RidePromoCard({
    required this.promo,
    required this.isSelected,
    required this.onApplyTap,
    required this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    return PromoCardShell(
      isSelected: isSelected,
      accentColor: AppColors.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PromoIconTile(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        promo.code,
                        style: AppTypography.label2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (promo.minSpend > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: Text(
                          'ขั้นต่ำ ฿${promo.minSpend.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFFFF8F00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  promo.name,
                  style: AppTypography.caption4.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  promo.description,
                  style: AppTypography.caption5.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: PromoApplyButton(
                    isSelected: isSelected,
                    onApply: onApplyTap,
                    onCancel: onCancelTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
