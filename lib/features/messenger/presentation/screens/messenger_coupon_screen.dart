import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/data/datasources/promo_remote_data_source.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the parcel checkout can use: promotions, then the customer's points
/// coupons (GET /api/customer/promos/context?applies_to=MESSENGER).
final messengerPromosProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) => ref.watch(promoRemoteDataSourceProvider).getForService('MESSENGER'),
);

/// Coupon picker for the messenger booking. Lets the user either type a code or
/// tap one from their promotions and points coupons. Returns the chosen code
/// string via `Navigator.pop`, or null if dismissed.
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
  void initState() {
    super.initState();
    // Fresh list every time the checkout coupon picker opens.
    Future.microtask(() {
      if (mounted) ref.invalidate(messengerPromosProvider);
    });
  }

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
    final promosAsync = ref.watch(messengerPromosProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          l10n.msgrSelectPromo,
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
            applyLabel: l10n.msgrApplyCode,
            hint: l10n.msgrEnterPromo,
          ),
          Expanded(
            child: promosAsync.when(
              loading: () => const Center(child: MassLoadingM(size: 72)),
              error: (error, stack) => Center(
                child: Text(
                  l10n.msgrLoadPromosFailed,
                  style: AppTypography.label2.copyWith(
                    color: AppColors.semanticGrayNeutralFgLowOnWhite,
                  ),
                ),
              ),
              data: (raw) {
                // Only promos usable on a messenger order (applies_to ALL or
                // MESSENGER) — a ride/food-only code can't be applied here.
                final all = raw
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .where(
                      (p) =>
                          (p['kind'] ?? '').toString().toUpperCase() ==
                              'VOUCHER' ||
                          promoAppliesToService(p, 'messenger'),
                    )
                    .toList();
                bool isVoucher(Map<String, dynamic> p) =>
                    (p['kind'] ?? '').toString().toUpperCase() == 'VOUCHER';
                // Promotions first, then the points coupons.
                final promos = [
                  ...all.where((p) => !isVoucher(p)),
                  ...all.where(isVoucher),
                ];
                if (promos.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.msgrNoPromos,
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
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.paddingOf(context).bottom),
                  itemCount: promos.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 12),
                        child: Text(
                          l10n.msgrAvailableCoupons,
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
                      applyLabel: l10n.msgrApplyCode,
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

