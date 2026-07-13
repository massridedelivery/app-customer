import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_vehicle_type.dart';
import 'package:customer_app/features/messenger/presentation/controllers/messenger_booking_controller.dart';
import 'package:customer_app/features/messenger/presentation/states/messenger_booking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MessengerBookingScreen extends ConsumerStatefulWidget {
  const MessengerBookingScreen({super.key});

  @override
  ConsumerState<MessengerBookingScreen> createState() =>
      _MessengerBookingScreenState();
}

class _MessengerBookingScreenState
    extends ConsumerState<MessengerBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _codAmountController = TextEditingController();
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _notesController.dispose();
    _codAmountController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  /// Thai phone per spec: `+66812345678` or `0812345678`.
  static final _thaiPhoneRegex = RegExp(r'^(\+66\d{9}|0\d{8,9})$');

  void _onDimensionsChanged() {
    ref.read(messengerBookingControllerProvider.notifier).setDimensions(
          lengthCm: double.tryParse(_lengthController.text),
          widthCm: double.tryParse(_widthController.text),
          heightCm: double.tryParse(_heightController.text),
        );
  }

  void _submit() {
    final homeState = ref.read(homeControllerProvider);
    if (homeState.dropoffLocation == null) {
      _showSnack('กรุณาเลือกจุดส่งพัสดุ', isError: true);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bookingState = ref.read(messengerBookingControllerProvider);
    if (bookingState.estimate == null || bookingState.isEstimating) {
      _showSnack('กำลังคำนวณราคา กรุณารอสักครู่', isError: true);
      return;
    }

    ref.read(messengerBookingControllerProvider.notifier).createOrder(
          recipientName: _recipientNameController.text.trim(),
          recipientPhone: _recipientPhoneController.text.trim(),
          notes: _notesController.text.trim(),
        );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(messengerBookingControllerProvider);
    final homeState = ref.watch(homeControllerProvider);

    ref.listen(messengerBookingControllerProvider, (previous, next) {
      if (next.createdOrderId != null &&
          next.createdOrderId != previous?.createdOrderId) {
        final orderId = next.createdOrderId!;
        // PromptPay must be paid before dispatch (SCRUM-35 §3.3): go through
        // the QR screen, which replaces itself with tracking on PAID. Pushed
        // (not replaced) so expiry/failure can fall back to this screen.
        if (next.paymentMethod.toUpperCase() == 'PROMPTPAY') {
          context.push(
            '/payment/promptpay',
            extra: {
              'orderId': orderId,
              'onPaidRoute': '/messenger/tracking/$orderId',
            },
          );
        } else {
          context.pushReplacement('/messenger/tracking/$orderId');
        }
      }
      if (next.error != null && next.error != previous?.error) {
        _showSnack(next.error!, isError: true);
        ref.read(messengerBookingControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.foundationGrayscale100,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'เมสเซนเจอร์ส่งพัสดุ',
          style: AppTypography.heading4.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildLocationCard(homeState),
            const SizedBox(height: 12),
            _buildVehicleAndSizeCard(bookingState),
            const SizedBox(height: 12),
            _buildPackageCard(bookingState),
            const SizedBox(height: 12),
            _buildRecipientCard(),
            const SizedBox(height: 12),
            _buildPaymentCard(bookingState),
            const SizedBox(height: 12),
            _buildEstimateCard(bookingState),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(bookingState),
    );
  }

  // ─── Location ──────────────────────────────────────────────────────────────

  Widget _buildLocationCard(HomeState homeState) {
    return _card(
      child: Column(
        children: [
          _locationRow(
            icon: Icons.trip_origin,
            iconColor: AppColors.foundationGreen500,
            label: 'จุดรับพัสดุ',
            address: homeState.pickupAddress ?? 'เลือกจุดรับพัสดุ',
            onTap: () {
              ref
                  .read(homeControllerProvider.notifier)
                  .startSelection(mode: RideSelectionMode.pickup);
              context.push('/select-pickup');
            },
          ),
          const Divider(height: 16, color: AppColors.foundationGrayscale200),
          _locationRow(
            icon: Icons.location_on,
            iconColor: AppColors.foundationRed700,
            label: 'จุดส่งพัสดุ',
            address: homeState.dropoffAddress ?? 'เลือกจุดส่งพัสดุ',
            isPlaceholder: homeState.dropoffAddress == null,
            onTap: () {
              ref
                  .read(homeControllerProvider.notifier)
                  .startSelection(mode: RideSelectionMode.messengerDropoff);
              context.push('/select-dropoff');
            },
          ),
        ],
      ),
    );
  }

  Widget _locationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
    required VoidCallback onTap,
    bool isPlaceholder = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPlaceholder
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.foundationGrayscale500,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Vehicle + Size tier ───────────────────────────────────────────────────

  Widget _buildVehicleAndSizeCard(MessengerBookingState bookingState) {
    if (bookingState.isLoadingVehicles) {
      return _card(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }
    if (bookingState.vehicleTypes.isEmpty) {
      return _card(
        child: Column(
          children: [
            Text(
              'ไม่พบบริการเมสเซนเจอร์ในขณะนี้',
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => ref
                  .read(messengerBookingControllerProvider.notifier)
                  .loadVehicleTypes(),
              child: const Text(
                'ลองใหม่',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    final List<MessengerVehicleType> vehicles = bookingState.vehicleTypes;
    final MessengerVehicleType? vehicle = bookingState.selectedVehicle;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ประเภทรถและขนาดพัสดุ',
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          if (vehicles.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              children: vehicles
                  .map<Widget>(
                    (v) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          v.displayName.isNotEmpty ? v.displayName : v.name,
                        ),
                        selected: v.id == bookingState.vehicleTypeId,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        labelStyle: AppTypography.caption4.copyWith(
                          color: v.id == bookingState.vehicleTypeId
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => ref
                            .read(messengerBookingControllerProvider.notifier)
                            .selectVehicle(v.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          if (vehicle != null)
            Row(
              children: vehicle.sizeTiers
                  .map<Widget>(
                    (tier) => Expanded(
                      child: _sizeTierCard(
                        tier,
                        tier.tier.toUpperCase() ==
                            bookingState.sizeTier.toUpperCase(),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _sizeTierCard(MessengerSizeTier tier, bool isSelected) {
    return GestureDetector(
      onTap: () => ref
          .read(messengerBookingControllerProvider.notifier)
          .selectSizeTier(tier.tier),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.foundationGrayscale300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              tier.tier.toUpperCase(),
              style: AppTypography.heading4.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '≤ ${tier.maxWeightKg} กก.',
              style: AppTypography.caption5.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '≤ ${tier.maxLengthCm}×${tier.maxWidthCm}×${tier.maxHeightCm} ซม.',
              style: AppTypography.support2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              tier.surchargeThb > 0 ? '+฿${tier.surchargeThb}' : 'ฟรี',
              style: AppTypography.caption4.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.foundationGreen500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Package details ───────────────────────────────────────────────────────

  Widget _buildPackageCard(MessengerBookingState bookingState) {
    final MessengerSizeTier? tier = bookingState.selectedSizeTier;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ข้อมูลพัสดุ',
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
              label: 'น้ำหนัก (กก.) *',
              hint: tier != null ? 'ไม่เกิน ${tier.maxWeightKg} กก.' : null,
            ),
            validator: (value) {
              final weight = double.tryParse(value ?? '');
              if (weight == null || weight <= 0) {
                return 'กรุณาระบุน้ำหนักพัสดุ';
              }
              if (tier != null && weight > tier.maxWeightKg) {
                return 'น้ำหนักเกินขนาด ${tier.tier} (สูงสุด ${tier.maxWeightKg} กก.)';
              }
              return null;
            },
            onChanged: (value) {
              ref
                  .read(messengerBookingControllerProvider.notifier)
                  .setWeight(double.tryParse(value) ?? 0);
            },
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            maintainState: true,
            title: Text(
              'ขนาดพัสดุ (ไม่บังคับ)',
              style: AppTypography.caption3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _dimensionField(
                      _lengthController,
                      'ยาว (ซม.)',
                      tier?.maxLengthCm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dimensionField(
                      _widthController,
                      'กว้าง (ซม.)',
                      tier?.maxWidthCm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dimensionField(
                      _heightController,
                      'สูง (ซม.)',
                      tier?.maxHeightCm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dimensionField(
    TextEditingController controller,
    String label,
    int? max,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label: label),
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final size = double.tryParse(value);
        if (size == null || size < 0) return 'ไม่ถูกต้อง';
        if (max != null && max > 0 && size > max) return 'เกิน $max ซม.';
        return null;
      },
      onChanged: (_) => _onDimensionsChanged(),
    );
  }

  // ─── Recipient ─────────────────────────────────────────────────────────────

  Widget _buildRecipientCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ข้อมูลผู้รับ',
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _recipientNameController,
            maxLength: 200,
            decoration: _inputDecoration(label: 'ชื่อผู้รับ', counter: false),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _recipientPhoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              label: 'เบอร์โทรผู้รับ',
              hint: 'เช่น 0812345678',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              if (!_thaiPhoneRegex.hasMatch(value.trim())) {
                return 'รูปแบบเบอร์โทรไม่ถูกต้อง';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLength: 1000,
            maxLines: 2,
            decoration: _inputDecoration(
              label: 'โน้ตถึงคนขับ (ไม่บังคับ)',
              hint: 'เช่น ของแตกง่าย',
              counter: false,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payment ───────────────────────────────────────────────────────────────

  Widget _buildPaymentCard(MessengerBookingState bookingState) {
    final bool isCod = bookingState.isCod;
    final String method = bookingState.paymentMethod.toUpperCase();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'วิธีชำระเงิน',
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _paymentOption(
                  'CASH',
                  'เงินสด',
                  Icons.payments_outlined,
                  method == 'CASH',
                ),
              ),
              const SizedBox(width: 8),
              // The QR/intent flow is wired (SCRUM-35 §3.3): PROMPTPAY orders
              // route through /payment/promptpay. NOTE: backend still gates
              // digital payment for messenger in phase 1 (SCRUM-41 accepts
              // CASH | COD) — creates fail with 400 until it opens up; the
              // error paths surface that gracefully.
              Expanded(
                child: _paymentOption(
                  'PROMPTPAY',
                  'พร้อมเพย์',
                  Icons.qr_code_2_rounded,
                  method == 'PROMPTPAY',
                ),
              ),
              // COD hidden behind a flag until its collection/settlement flow
              // is finalised (FeatureFlags.messengerCodEnabled).
              if (FeatureFlags.messengerCodEnabled) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _paymentOption(
                    'COD',
                    'เก็บเงินปลายทาง',
                    Icons.local_atm,
                    method == 'COD',
                  ),
                ),
              ],
            ],
          ),
          if (FeatureFlags.messengerCodEnabled && isCod) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _codAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration(
                label: 'ยอดเก็บเงินปลายทาง (บาท) *',
                hint: 'ไม่เกิน 100,000 บาท',
              ),
              validator: (value) {
                if (!ref.read(messengerBookingControllerProvider).isCod) {
                  return null;
                }
                final amount = double.tryParse(value ?? '');
                if (amount == null || amount <= 0) {
                  return 'กรุณาระบุยอดเก็บเงินปลายทาง';
                }
                if (amount > 100000) return 'ยอดสูงสุด 100,000 บาท';
                return null;
              },
              onChanged: (value) {
                ref
                    .read(messengerBookingControllerProvider.notifier)
                    .setCodAmount(double.tryParse(value) ?? 0);
              },
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _promoController,
            maxLength: 40,
            decoration: _inputDecoration(
              label: 'โค้ดส่วนลด (ไม่บังคับ)',
              counter: false,
            ),
            onFieldSubmitted: (value) => ref
                .read(messengerBookingControllerProvider.notifier)
                .setPromoCode(value.trim()),
            onTapOutside: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
              ref
                  .read(messengerBookingControllerProvider.notifier)
                  .setPromoCode(_promoController.text.trim());
            },
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(
    String value,
    String label,
    IconData icon,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => ref
          .read(messengerBookingControllerProvider.notifier)
          .setPaymentMethod(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.foundationGrayscale300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTypography.caption4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Estimate summary ──────────────────────────────────────────────────────

  Widget _buildEstimateCard(MessengerBookingState bookingState) {
    if (bookingState.isEstimating) {
      return _card(
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'กำลังคำนวณราคา...',
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final estimate = bookingState.estimate;
    if (estimate == null) {
      return _card(
        child: Text(
          'เลือกจุดส่งและระบุน้ำหนักพัสดุเพื่อดูราคา',
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สรุปราคา',
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _priceRow(
            'ระยะทาง',
            '${estimate.distanceKm.toStringAsFixed(1)} กม. (~${estimate.durationMin.round()} นาที)',
          ),
          _priceRow('ค่าส่ง', '฿${estimate.baseFare.toStringAsFixed(0)}'),
          if (estimate.surcharge > 0)
            _priceRow(
              'ค่าธรรมเนียมขนาด',
              '฿${estimate.surcharge.toStringAsFixed(0)}',
            ),
          if (estimate.discount > 0)
            _priceRow(
              'ส่วนลด',
              '-฿${estimate.discount.toStringAsFixed(0)}',
              valueColor: AppColors.foundationGreen500,
            ),
          const Divider(height: 16, color: AppColors.foundationGrayscale200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ยอดชำระ',
                style: AppTypography.heading5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '฿${estimate.totalFare.toStringAsFixed(0)}',
                style: AppTypography.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTypography.body2.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom CTA ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(MessengerBookingState bookingState) {
    final estimate = bookingState.estimate;
    final bool canSubmit = estimate != null &&
        !bookingState.isEstimating &&
        !bookingState.isCreating;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: canSubmit ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.foundationGrayscale300,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: bookingState.isCreating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  estimate != null
                      ? 'เรียกเมสเซนเจอร์ • ฿${estimate.totalFare.toStringAsFixed(0)}'
                      : 'เรียกเมสเซนเจอร์',
                  style: AppTypography.heading5.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.foundationGrayscale200),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    bool counter = true,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: counter ? null : '',
      labelStyle: AppTypography.caption3.copyWith(
        color: AppColors.textSecondary,
      ),
      hintStyle: AppTypography.caption3.copyWith(
        color: AppColors.foundationGrayscale400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.foundationGrayscale300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.foundationGrayscale300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
