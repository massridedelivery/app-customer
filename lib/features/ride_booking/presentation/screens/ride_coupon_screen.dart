import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/providers/discover_promos_provider.dart';
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
          _errorMessage = 'รหัสส่วนลดไม่ถูกต้อง';
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
                // SECTION 1: Manual promo code input (shared widget)
                CouponManualEntry(
                  controller: _manualController,
                  onApply: _applyPromo,
                  applyLabel: 'ใช้งาน',
                  errorText: _errorMessage,
                  isLoading: _isLoading,
                  onChanged: () {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),

                // SECTION 2: List of promotions (Scrollable)
                Expanded(
                  child: promosAsync.when(
                    loading: () => const Center(
                      child: MassLoadingM(size: 72),
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
                            return CouponCard(
                              data: CouponCardData.fromRidePromo(promo),
                              isSelected: isSelected,
                              onApply: () => _applyPromo(promo.code),
                              onCancel: _cancelPromo,
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

