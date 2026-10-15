import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/utils/auth_gate.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/hero_header.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_estimate.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_vehicle_type.dart';
import 'package:customer_app/features/messenger/presentation/controllers/messenger_booking_controller.dart';
import 'package:customer_app/features/messenger/presentation/states/messenger_booking_state.dart';
import 'package:customer_app/features/messenger/presentation/util/delivery_service_levels.dart';
import 'package:customer_app/features/messenger/presentation/screens/messenger_coupon_screen.dart';
import 'package:customer_app/core/widgets/location_access_hint.dart';
import 'package:customer_app/l10n/app_localizations.dart';
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
  void initState() {
    super.initState();
    // Default the parcel pickup (จุดรับ) to the app's current delivery location
    // — the top "เลือกสถานที่จัดส่ง" selector (foodLocation). So when the user
    // changes that place, the messenger pickup follows it by default here; they
    // can still tap จุดรับ to pick a different one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final home = ref.read(homeControllerProvider);
      final deliveryLoc = home.foodLocation;
      if (deliveryLoc != null && home.pickupLocation != deliveryLoc) {
        ref.read(homeControllerProvider.notifier).setPickupLocation(
              deliveryLoc,
              home.foodAddress ?? '',
            );
      }
    });
  }

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

  /// Thai phone per spec: `+66812345678` or `0812345678` — 10 digits in the
  /// `0…` form (the backend's `phone_th` validator rejects a shorter number, so
  /// require the full length here to catch it before submitting).
  static final _thaiPhoneRegex = RegExp(r'^(\+66\d{9}|0\d{9})$');

  void _onDimensionsChanged() {
    ref.read(messengerBookingControllerProvider.notifier).setDimensions(
          lengthCm: double.tryParse(_lengthController.text),
          widthCm: double.tryParse(_widthController.text),
          heightCm: double.tryParse(_heightController.text),
        );
  }

  void _submit() {
    final homeState = ref.read(homeControllerProvider);
    if (homeState.pickupLocation == null) {
      _showSnack(_l10n.msgrSelectPickupError, isError: true);
      return;
    }
    if (homeState.dropoffLocation == null) {
      _showSnack(_l10n.msgrSelectDropoffError, isError: true);
      return;
    }

    // Recipient name/phone live in the "ข้อมูลผู้รับ" card near the bottom of the
    // ListView. ListView builds its children lazily, so those TextFormFields may
    // not be mounted when the user never scrolled down to them — and an unmounted
    // field is not registered with the Form, so `_formKey.validate()` silently
    // skips it and the order goes through with no recipient. Guard with the
    // controllers directly (they always hold the current text), so these two
    // fields can never be bypassed regardless of scroll position.
    final recipientName = _recipientNameController.text.trim();
    final recipientPhone = _recipientPhoneController.text.trim();
    if (recipientName.isEmpty) {
      _showSnack(_l10n.msgrRecipientNameRequired, isError: true);
      return;
    }
    if (recipientPhone.isEmpty) {
      _showSnack(_l10n.msgrRecipientPhoneRequired, isError: true);
      return;
    }
    if (!_thaiPhoneRegex.hasMatch(recipientPhone)) {
      _showSnack(_l10n.msgrRecipientPhoneInvalid, isError: true);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bookingState = ref.read(messengerBookingControllerProvider);
    if (bookingState.estimate == null || bookingState.isEstimating) {
      _showSnack(_l10n.msgrCalculatingPleaseWait, isError: true);
      return;
    }

    // Sending a parcel is account-based — a guest must log in first.
    if (!ensureLoggedIn(context, ref)) return;

    ref.read(messengerBookingControllerProvider.notifier).createOrder(
          recipientName: recipientName,
          recipientPhone: recipientPhone,
          notes: _notesController.text.trim(),
        );
  }

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

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
        // Pay-after-match (dev): the sender is no longer charged before a driver
        // is found. Every order — cash, recipient-pays, and sender-pays
        // PromptPay alike — now dispatches unpaid and goes straight to tracking.
        // Sender-pays PromptPay is collected once the driver reaches pickup: the
        // tracking screen surfaces the QR then (see awaitingPromptPay).
        context.pushReplacement('/messenger/tracking/$orderId');
      }
      if (next.error != null && next.error != previous?.error) {
        _showSnack(next.error!, isError: true);
        ref.read(messengerBookingControllerProvider.notifier).clearError();
      }
    });

    // Floating wave hero over a scrolling list: the cards scroll up UNDER the
    // red wave and the first card tucks beneath the curve, so content peeks
    // through the transparent dip (matches the home header's overlap).
    final double statusPadding = MediaQuery.of(context).padding.top;
    const double heroBody = 172; // red height below the status bar
    final double heroHeight = statusPadding + heroBody;
    // Small gap so the first card sits clear below the wave at rest — the
    // deepest dip is on the left, right over the pickup/dropoff pins, so any
    // overlap would cover them. Content still scrolls up under the wave.
    const double topGap = 12;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, heroHeight + topGap, 16, 24),
                children: [
                  _buildLocationCard(homeState),
                  const SizedBox(height: 12),
                  _buildVehicleCard(bookingState),
                  const SizedBox(height: 12),
                  _buildSizeCard(bookingState),
                  const SizedBox(height: 12),
                  _buildPackageCard(bookingState),
                  const SizedBox(height: 12),
                  _buildRecipientCard(),
                  const SizedBox(height: 12),
                  _buildDeliveryTypeCard(bookingState),
                  const SizedBox(height: 12),
                  _buildPayerCard(bookingState),
                  const SizedBox(height: 12),
                  _buildPaymentCard(bookingState),
                  const SizedBox(height: 12),
                  _buildEstimateCard(bookingState),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: _buildHero(context),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(bookingState),
    );
  }

  /// Branded gradient hero with a wave-clipped bottom — matches the ride
  /// ("รับส่งคน") landing header style.
  Widget _buildHero(BuildContext context) {
    return ClipPath(
      clipper: HeroWaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.foundationRed700, AppColors.foundationRed900],
          ),
        ),
        child: Stack(
          children: [
            const HeroPatternOverlay(),
            SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _l10n.msgrTitle,
                  style: AppTypography.heading2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  _l10n.msgrHeroSubtitle,
                  style: AppTypography.caption3.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  // ─── Location ──────────────────────────────────────────────────────────────

  Widget _buildLocationCard(HomeState homeState) {
    // A pickup is set when it has coordinates — the address may still be null
    // (reverse geocoding failed), and an address alone used to be faked by
    // location-error text.
    final bool hasPickup = homeState.pickupLocation != null;
    final String pickupLabel = homeState.pickupAddress ??
        (hasPickup
            ? AppLocalizations.of(context)!.currentLocation
            : _l10n.msgrSelectPickup);
    final bool hasDropoff = homeState.dropoffAddress != null &&
        homeState.dropoffAddress!.isNotEmpty;
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinned route column: green (pickup) → dotted line → red (dropoff),
          // matching the ride booking-details layout.
          Column(
            children: [
              const SizedBox(height: 18),
              AppIcons.asset(
                AppAssets.icLocationFill,
                color: AppColors.foundationGreen500,
                width: 22,
                height: 22,
              ),
              ...List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppColors.foundationGrayscale400,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              AppIcons.asset(
                AppAssets.icLocationFill,
                color: AppColors.foundationRed700,
                width: 22,
                height: 22,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _addressPill(
                  address: pickupLabel,
                  isPlaceholder: !hasPickup,
                  onTap: () {
                    ref
                        .read(homeControllerProvider.notifier)
                        .startSelection(mode: RideSelectionMode.pickup);
                    context.push('/messenger-place-search');
                  },
                ),
                const SizedBox(height: 12),
                _addressPill(
                  address: homeState.dropoffAddress ?? _l10n.msgrSelectDropoff,
                  isPlaceholder: !hasDropoff,
                  onTap: () {
                    ref
                        .read(homeControllerProvider.notifier)
                        .startSelection(
                          mode: RideSelectionMode.messengerDropoff,
                        );
                    context.push('/messenger-place-search');
                  },
                ),
                const LocationAccessHint(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressPill({
    required String address,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.foundationGrayscale300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                address,
                style: AppTypography.body2.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isPlaceholder
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.map_outlined, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Vehicle + Size tier ───────────────────────────────────────────────────

  // ─── Delivery mode (STOPGAP: client-side pricing/time until SCRUM-71) ────────

  Widget _buildDeliveryTypeCard(MessengerBookingState bookingState) {
    // Render strictly from the backend's enabled modes (SCRUM-71) — never
    // hardcode the modes; a mode the admin disabled simply isn't in the list.
    final levels = bookingState.serviceLevels;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.msgrDeliveryTypeTitle,
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (levels.isEmpty)
            Text(
              _l10n.msgrDeliveryOptionsHint,
              style: AppTypography.caption4.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            // Same Style-D grid cards as the other pickers.
            _grid2(
              levels.map<Widget>((level) {
                final bool isInstant =
                    level.deliveryType == kDeliveryInstant;
                final String title = level.label.isNotEmpty
                    ? level.label
                    : level.deliveryType;
                final l10n = AppLocalizations.of(context)!;
                final DateTime? deliverBy = parseDeliverBy(level.deliverBy);
                final String pickup = level.pickupEtaMin != null
                    ? l10n.pickupInMinutes(level.pickupEtaMin!)
                    : '';
                final String subtitle = deliverBy != null
                    ? '${l10n.deliverByAround(AppDates.of(context).time(deliverBy))}${pickup.isNotEmpty ? '\n$pickup' : ''}'
                    : pickup;
                return _selectableCard(
                  selected:
                      level.deliveryType == bookingState.deliveryType,
                  onTap: () => ref
                      .read(messengerBookingControllerProvider.notifier)
                      .selectDeliveryType(level.deliveryType),
                  icon: isInstant
                      ? Icons.bolt_rounded
                      : Icons.schedule_rounded,
                  title: title,
                  subtitle: subtitle.isEmpty ? null : subtitle,
                  trailing: Text(
                    '฿${level.totalFare.toStringAsFixed(0)}',
                    style: AppTypography.caption4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(MessengerBookingState bookingState) {
    if (bookingState.isLoadingVehicles) {
      return _card(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: MassLoadingM(size: 72),
          ),
        ),
      );
    }
    if (bookingState.vehicleTypes.isEmpty) {
      return _card(
        child: Column(
          children: [
            Text(
              _l10n.msgrNoService,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => ref
                  .read(messengerBookingControllerProvider.notifier)
                  .loadVehicleTypes(),
              child: Text(
                _l10n.retry,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    final List<MessengerVehicleType> vehicles = bookingState.vehicleTypes;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.msgrVehicleType,
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // 3D render + short label, same Style-D selected treatment.
          _grid2(
            vehicles
                .map<Widget>(
                  (v) => _vehicleCard(
                    selected: v.id == bookingState.vehicleTypeId,
                    onTap: () => ref
                        .read(messengerBookingControllerProvider.notifier)
                        .selectVehicle(v.id),
                    imagePath: _msgVehicleImage(v),
                    title: _msgVehicleLabel(v),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Parcel size-tier picker — its own card, shown once a vehicle is selected.
  Widget _buildSizeCard(MessengerBookingState bookingState) {
    final MessengerVehicleType? vehicle = bookingState.selectedVehicle;
    if (vehicle == null || vehicle.sizeTiers.isEmpty) {
      return const SizedBox.shrink();
    }
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.msgrPackageSize,
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _grid2(
            vehicle.sizeTiers
                .map<Widget>(
                  (tier) => _selectableCard(
                    selected: tier.tier.toUpperCase() ==
                        bookingState.sizeTier.toUpperCase(),
                    onTap: () => ref
                        .read(messengerBookingControllerProvider.notifier)
                        .selectSizeTier(tier.tier),
                    badgeText: tier.tier.toUpperCase(),
                    title: _msgSizeLabel(tier.tier),
                    subtitle: _l10n.msgrSizeTierLimits(
                      '${tier.maxWeightKg}',
                      '${tier.maxLengthCm}',
                      '${tier.maxWidthCm}',
                      '${tier.maxHeightCm}',
                    ),
                    trailing: Text(
                      tier.surchargeThb > 0
                          ? '+฿${tier.surchargeThb}'
                          : _l10n.msgrFree,
                      style: AppTypography.caption4.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.foundationGreen500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// A 3D vehicle render for a messenger type (bike vs car) — the API has no
  /// image field, so pick from the shared icon set by name.
  String _msgVehicleImage(MessengerVehicleType v) {
    final n = '${v.name} ${v.displayName}'.toLowerCase();
    if (n.contains('bike') ||
        n.contains('motor') ||
        n.contains('มอเตอร์')) {
      return 'assets/images/icons/3d/ic_car_scooter.png';
    }
    return 'assets/images/icons/3d/ic_car_economy.png';
  }

  /// Localized vehicle label (th: มอเตอร์ไซค์/รถยนต์, en: Bike/Car), picked from
  /// the API type name; falls back to the API label without the "Messenger"
  /// prefix for any other type.
  String _msgVehicleLabel(MessengerVehicleType v) {
    final l10n = AppLocalizations.of(context)!;
    final n = '${v.name} ${v.displayName}'.toLowerCase();
    if (n.contains('bike') || n.contains('motor') || n.contains('มอเตอร์')) {
      return l10n.msgVehicleBike;
    }
    if (n.contains('car')) {
      return l10n.msgVehicleCar;
    }
    final raw = v.displayName.isNotEmpty ? v.displayName : v.name;
    final stripped =
        raw.replaceAll(RegExp('messenger', caseSensitive: false), '').trim();
    return stripped.isNotEmpty ? stripped : raw;
  }

  /// Localized parcel-size label (th: ขนาดเล็ก/กลาง/ใหญ่, en: Small/Medium/Large).
  String _msgSizeLabel(String tier) {
    final l10n = AppLocalizations.of(context)!;
    switch (tier.toUpperCase()) {
      case 'S':
        return l10n.msgSizeSmall;
      case 'M':
        return l10n.msgSizeMedium;
      case 'L':
        return l10n.msgSizeLarge;
      default:
        return l10n.msgrSizeTier(tier.toUpperCase());
    }
  }

  /// Style-D card for a vehicle type: a 3D render on top with a centered label,
  /// matching the size/payer/payment cards' selected treatment.
  Widget _vehicleCard({
    required bool selected,
    required VoidCallback onTap,
    required String imagePath,
    required String title,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, selected ? -2 : 0, 0),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.foundationGrayscale300,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTypography.label1.copyWith(
                fontWeight: FontWeight.bold,
                color: selected
                    ? AppColors.foundationRed700
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lays selectable cards out in a 2-column grid (paired rows of equal
  /// height). An odd last card keeps its half-width slot, left-aligned.
  Widget _grid2(List<Widget> cells) {
    const double gap = 8;
    final List<Widget> rows = [];
    for (int i = 0; i < cells.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cells[i]),
            const SizedBox(width: gap),
            if (i + 1 < cells.length)
              Expanded(child: cells[i + 1])
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < cells.length) rows.add(const SizedBox(height: gap));
    }
    return Column(children: rows);
  }

  /// Shared selectable grid card used by the size, payer, and payment pickers
  /// so all three match: a circular leading badge (an [icon] or short
  /// [badgeText]) with optional [trailing] on the same row, then title +
  /// optional subtitle below, and a red outline + tint when selected.
  Widget _selectableCard({
    required bool selected,
    required VoidCallback onTap,
    required String title,
    String? subtitle,
    IconData? icon,
    String? badgeText,
    Widget? trailing,
  }) {
    final Color badgeFg = selected ? Colors.white : AppColors.textSecondary;
    final Color badgeBg =
        selected ? AppColors.primary : AppColors.foundationGrayscale200;
    // Selected: card lifts with a soft black shadow and a thin red border.
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, selected ? -2 : 0, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.foundationGrayscale300,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: badgeText != null
                      ? Text(
                          badgeText,
                          style: AppTypography.label1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: badgeFg,
                          ),
                        )
                      : Icon(icon, size: 20, color: badgeFg),
                ),
                if (trailing != null) ...[const Spacer(), trailing],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.label1.copyWith(
                fontWeight: FontWeight.bold,
                color: selected
                    ? AppColors.foundationRed700
                    : AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption5.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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
            _l10n.msgrPackageInfo,
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Show the "over the size limit" error live as they type, not only
            // on submit.
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _inputDecoration(
              label: _l10n.msgrWeightLabel,
              hint: tier != null
                  ? _l10n.msgrWeightHint('${tier.maxWeightKg}')
                  : null,
            ),
            validator: (value) {
              final weight = double.tryParse(value ?? '');
              if (weight == null || weight <= 0) {
                return _l10n.msgrWeightRequired;
              }
              if (tier != null && weight > tier.maxWeightKg) {
                return _l10n.msgrWeightOverTier(tier.tier, '${tier.maxWeightKg}');
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
              _l10n.msgrDimensionsOptional,
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
                      _l10n.msgrLengthCm,
                      tier?.maxLengthCm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dimensionField(
                      _widthController,
                      _l10n.msgrWidthCm,
                      tier?.maxWidthCm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dimensionField(
                      _heightController,
                      _l10n.msgrHeightCm,
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
        if (size == null || size < 0) return _l10n.msgrInvalid;
        if (max != null && max > 0 && size > max) return _l10n.msgrOverMaxCm('$max');
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
            _l10n.msgrRecipientInfo,
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _recipientNameController,
            maxLength: 200,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _inputDecoration(
              label: _l10n.msgrRecipientNameLabel,
              counter: false,
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty)
                ? _l10n.msgrRecipientNameRequired
                : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _recipientPhoneController,
            keyboardType: TextInputType.phone,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _inputDecoration(
              label: _l10n.msgrRecipientPhoneLabel,
              hint: _l10n.msgrRecipientPhoneHint,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _l10n.msgrRecipientPhoneRequired;
              }
              if (!_thaiPhoneRegex.hasMatch(value.trim())) {
                return _l10n.msgrPhoneInvalid;
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
              label: _l10n.msgrNotesLabel,
              hint: _l10n.msgrNotesHint,
              counter: false,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payer (who pays the delivery fee) ──────────────────────────────────────

  Widget _buildPayerCard(MessengerBookingState bookingState) {
    final String payer = bookingState.payer.toUpperCase();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.msgrPayerTitle,
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _grid2([
            _selectableCard(
              selected: payer == 'SENDER',
              onTap: () => ref
                  .read(messengerBookingControllerProvider.notifier)
                  .setPayer('SENDER'),
              icon: Icons.person_outline,
              title: _l10n.msgrPayerSender,
              subtitle: _l10n.msgrPayerSenderSub,
            ),
            _selectableCard(
              selected: payer == 'RECIPIENT',
              onTap: () => ref
                  .read(messengerBookingControllerProvider.notifier)
                  .setPayer('RECIPIENT'),
              icon: Icons.pin_drop_outlined,
              title: _l10n.msgrPayerRecipient,
              subtitle: _l10n.msgrPayerRecipientSub,
            ),
          ]),
          if (bookingState.isRecipientPays) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _l10n.msgrRecipientPaysNote,
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            _l10n.msgrPaymentMethod,
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _grid2([
            _selectableCard(
              selected: method == 'CASH',
              onTap: () => ref
                  .read(messengerBookingControllerProvider.notifier)
                  .setPaymentMethod('CASH'),
              icon: Icons.payments_outlined,
              title: _l10n.cashLabel,
            ),
            // PromptPay is gated off until the messenger backend accepts
            // digital payment (SCRUM-41 phase 1 = CASH|COD; PROMPTPAY 400s).
            if (FeatureFlags.messengerPromptPayEnabled)
              _selectableCard(
                selected: method == 'PROMPTPAY',
                onTap: () => ref
                    .read(messengerBookingControllerProvider.notifier)
                    .setPaymentMethod('PROMPTPAY'),
                icon: Icons.qr_code_2_rounded,
                title: _l10n.promptPay,
              ),
            // COD hidden behind a flag until its collection/settlement flow
            // is finalised (FeatureFlags.messengerCodEnabled).
            if (FeatureFlags.messengerCodEnabled)
              _selectableCard(
                selected: method == 'COD',
                onTap: () => ref
                    .read(messengerBookingControllerProvider.notifier)
                    .setPaymentMethod('COD'),
                icon: Icons.local_atm,
                title: _l10n.msgrCod,
              ),
          ]),
          if (FeatureFlags.messengerCodEnabled && isCod) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _codAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration(
                label: _l10n.msgrCodAmountLabel,
                hint: _l10n.msgrCodAmountHint,
              ),
              validator: (value) {
                if (!ref.read(messengerBookingControllerProvider).isCod) {
                  return null;
                }
                final amount = double.tryParse(value ?? '');
                if (amount == null || amount <= 0) {
                  return _l10n.msgrCodAmountRequired;
                }
                if (amount > 100000) return _l10n.msgrCodAmountMax;
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
          // Tap to pick a discount code (or type one) on the coupon screen.
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final current = ref
                  .read(messengerBookingControllerProvider)
                  .promoCode;
              final code = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) =>
                      MessengerCouponScreen(initialCode: current),
                ),
              );
              if (code != null) {
                setState(() => _promoController.text = code);
                ref
                    .read(messengerBookingControllerProvider.notifier)
                    .setPromoCode(code.trim());
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.foundationGrayscale300),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _promoController.text.isNotEmpty
                          ? _promoController.text
                          : _l10n.msgrSelectPromoOptional,
                      style: AppTypography.body2.copyWith(
                        color: _promoController.text.isNotEmpty
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.foundationGrayscale400,
                  ),
                ],
              ),
            ),
          ),
        ],
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
              _l10n.msgrCalculating,
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
          _l10n.msgrPriceHint,
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.msgrPriceSummary,
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _priceRow(
            _l10n.distance,
            _l10n.msgrDistanceDuration(
              estimate.distanceKm.toStringAsFixed(1),
              '${estimate.durationMin.round()}',
            ),
          ),
          ..._fareLines(bookingState, estimate),
          const Divider(height: 16, color: AppColors.foundationGrayscale200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _l10n.msgrTotal,
                style: AppTypography.heading5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '฿${bookingState.displayTotalFare.toStringAsFixed(0)}',
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

  /// Fare line items for the selected delivery mode. The per-mode entry in
  /// `service_levels[]` splits the size and express surcharges; the top-level
  /// `surcharge` lumps them together (and only for INSTANT), so it must not be
  /// labelled as the size fee.
  List<Widget> _fareLines(
    MessengerBookingState bookingState,
    MessengerEstimate estimate,
  ) {
    final level = bookingState.selectedServiceLevel;
    if (level != null) {
      return [
        _priceRow(
          _l10n.msgrDeliveryFee,
          '฿${level.baseFare.toStringAsFixed(0)}',
        ),
        if (level.sizeSurcharge > 0)
          _priceRow(
            _l10n.msgrSizeFee,
            '฿${level.sizeSurcharge.toStringAsFixed(0)}',
          ),
        if (level.expressSurcharge > 0)
          _priceRow(
            _l10n.msgrExpressFee,
            '฿${level.expressSurcharge.toStringAsFixed(0)}',
          ),
        if (level.discount > 0)
          _priceRow(
            _l10n.msgrDiscount,
            '-฿${level.discount.toStringAsFixed(0)}',
            valueColor: AppColors.foundationGreen500,
          ),
      ];
    }
    // No per-mode pricing from BE: show the top-level lines as they are.
    return [
      _priceRow(
        _l10n.msgrDeliveryFee,
        '฿${estimate.baseFare.toStringAsFixed(0)}',
      ),
      if (estimate.surcharge > 0)
        _priceRow(
          _l10n.msgrExtraFee,
          '฿${estimate.surcharge.toStringAsFixed(0)}',
        ),
      if (estimate.discount > 0)
        _priceRow(
          _l10n.msgrDiscount,
          '-฿${estimate.discount.toStringAsFixed(0)}',
          valueColor: AppColors.foundationGreen500,
        ),
    ];
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
                      ? _l10n.msgrCallMessengerPrice(
                          bookingState.displayTotalFare.toStringAsFixed(0),
                        )
                      : _l10n.msgrCallMessenger,
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
        borderRadius: BorderRadius.circular(18),
        // White page, borderless cards that float on a clear soft shadow.
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF110C0A).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
