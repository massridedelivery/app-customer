import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/auth_gate.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
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
    // Validating / applying a code is account-based; a guest logs in first.
    if (!ensureLoggedIn(context, ref)) return;

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
    // `promos/context` is token-scoped: as a guest it answered 401 "missing
    // authorization header" (shown raw) — so guests browse the public promo
    // list instead, narrowed to what applies to a ride.
    final isAuthed = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );

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
                  child: isAuthed
                      ? _buildMemberList(appliedPromoCode)
                      : _buildGuestList(),
                ),
              ],
        ),
      ),
    );
  }

  Widget _buildMemberList(String? appliedPromoCode) {
    final promosAsync = ref.watch(discoverPromosProvider);
    return promosAsync.when(
      loading: () => const Center(child: MassLoadingM(size: 72)),
      error: (err, stack) => _ErrorView(
        message: friendlyError(err, fallback: 'โหลดคูปองไม่สำเร็จ'),
        onRetry: () => ref.invalidate(discoverPromosProvider),
      ),
      data: (promos) => _CouponList(
        onRefresh: () => ref.refresh(discoverPromosProvider.future),
        cards: [
          for (final promo in promos)
            CouponCard(
              data: CouponCardData.fromRidePromo(promo),
              isSelected: appliedPromoCode == promo.code,
              onApply: () => _applyPromo(promo.code),
              onCancel: _cancelPromo,
            ),
        ],
      ),
    );
  }

  /// Guest view: public promos that apply to a ride. Tapping "ใช้คูปอง" asks
  /// the guest to log in (see [_applyPromo]).
  Widget _buildGuestList() {
    final promosAsync = ref.watch(promoListProvider);
    return promosAsync.when(
      loading: () => const Center(child: MassLoadingM(size: 72)),
      error: (err, stack) => _ErrorView(
        message: friendlyError(err, fallback: 'โหลดคูปองไม่สำเร็จ'),
        onRetry: () => ref.invalidate(promoListProvider),
      ),
      data: (raw) {
        final promos = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((p) => promoAppliesToService(p, 'ride'))
            .toList();
        return _CouponList(
          onRefresh: () => ref.refresh(promoListProvider.future),
          cards: [
            for (final promo in promos)
              CouponCard(
                data: CouponCardData.fromMap(promo),
                onApply: () => _applyPromo((promo['code'] ?? '').toString()),
                onCancel: _cancelPromo,
              ),
          ],
        );
      },
    );
  }
}

/// "คูปองส่วนลดที่มี" header + cards (or an empty message), pull-to-refresh.
class _CouponList extends StatelessWidget {
  final List<Widget> cards;
  final Future<Object?> Function() onRefresh;
  const _CouponList({required this.cards, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Text(
              'คูปองส่วนลดที่มี',
              style: AppTypography.label1.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: Text(
                  'ไม่มีคูปองที่สามารถใช้งานได้ในขณะนี้',
                  style: AppTypography.label2.copyWith(color: Colors.grey),
                ),
              ),
            )
          else
            ...cards,
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.caption4.copyWith(color: AppColors.error),
            ),
            TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
          ],
        ),
      ),
    );
  }
}
