import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/hero_header.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/core/widgets/route_stops.dart';
import 'package:customer_app/features/advance_booking/domain/advance_config.dart';
import 'package:customer_app/features/advance_booking/domain/advance_refusal.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_booking_controller.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_common.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_confirm_screen.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_time_sheet.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/features/ride_booking/presentation/vehicle_icon.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/advance-booking`: the red wave hero with a calendar (Header H3), a short
/// route, the pickup time card and the vehicles side by side with locked
/// prices (Booking C). Next: `/advance-booking/confirm`.
class AdvanceBookingScreen extends ConsumerStatefulWidget {
  const AdvanceBookingScreen({super.key});

  @override
  ConsumerState<AdvanceBookingScreen> createState() =>
      _AdvanceBookingScreenState();
}

class _AdvanceBookingScreenState extends ConsumerState<AdvanceBookingScreen> {
  bool _askedTime = false;

  /// Opens the place search (in advance mode, so it comes back here).
  Future<void> _editRoute({required bool pickup}) async {
    await context.push(
      '/place-search?advance=1${pickup ? '&focus=pickup' : ''}',
    );
    if (!mounted) return;
    final ctrl = ref.read(advanceBookingControllerProvider.notifier);
    if (ref.read(advanceBookingControllerProvider).scheduledAt == null) {
      _maybeAskTime();
    } else {
      ctrl.loadOptions();
    }
  }

  bool get _routeReady {
    final home = ref.read(homeControllerProvider);
    return home.pickupLocation != null && home.dropoffLocation != null;
  }

  Future<void> _pickTime(AdvanceConfig config) async {
    final state = ref.read(advanceBookingControllerProvider);
    final at = await showAdvanceTimeSheet(
      context,
      config: config,
      initial: state.scheduledAt,
      vehicle: state.selected?.type,
    );
    if (at == null || !mounted) return;
    await ref.read(advanceBookingControllerProvider.notifier).setTime(at);
  }

  /// On to the confirm screen; back with [advanceRetimeResult] when the time
  /// no longer fits, so ask for another.
  Future<void> _next(AdvanceConfig config) async {
    final result = await context.push<Object?>('/advance-booking/confirm');
    if (!mounted || result != advanceRetimeResult) return;
    final fresh = await ref.read(advanceConfigProvider.future);
    if (mounted) await _pickTime(fresh);
  }

  /// First visit: ask for the route if missing, then the time.
  void _maybeAskTime() {
    if (_askedTime) return;
    final config = ref.read(advanceConfigProvider).value;
    if (config == null || !config.enabled) return;
    if (!_routeReady) return;
    _askedTime = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pickTime(config);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configAsync = ref.watch(advanceConfigProvider);
    final home = ref.watch(homeControllerProvider);
    final state = ref.watch(advanceBookingControllerProvider);
    final fmt = advanceFormatOf(context);
    final now = DateTime.now();

    ref.listen(advanceConfigProvider, (_, next) {
      if (next.value != null) _maybeAskTime();
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _Hero(
              title: l10n.advanceScreenTitle,
              subtitle: l10n.advanceHeroSubtitle,
              month: fmt.monthShort(state.scheduledAt ?? now.toUtc()),
              day: fmt.dayOfMonth(state.scheduledAt ?? now.toUtc()),
              weekday: fmt.weekdayName(state.scheduledAt ?? now.toUtc()),
            ),
            Expanded(
              child: configAsync.when(
                loading: () => const Center(child: MassLoadingM(size: 72)),
                error: (_, _) => _Retry(
                  text: l10n.advanceLoadFailed,
                  onRetry: () => ref.invalidate(advanceConfigProvider),
                ),
                data: (config) {
                  if (!config.enabled) return _Closed(config: config);
                  _maybeAskTime();
                  final at = state.scheduledAt;
                  final selected = state.selected;
                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          children: [
                            _ShortRoute(
                              pickup: home.pickupAddress?.isNotEmpty == true
                                  ? home.pickupAddress
                                  : null,
                              dropoff: home.dropoffAddress?.isNotEmpty == true
                                  ? home.dropoffAddress
                                  : null,
                              pickupHint: l10n.advancePickupHint,
                              dropoffHint: l10n.advanceDropoffHint,
                              onEdit: (pickup) => _editRoute(pickup: pickup),
                            ),
                            const SizedBox(height: 10),
                            if (at == null)
                              _ChooseTime(
                                text: l10n.advanceChooseTime,
                                onTap: _routeReady
                                    ? () => _pickTime(config)
                                    : null,
                              )
                            else
                              GestureDetector(
                                key: const Key('advanceTimeBar'),
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _pickTime(config),
                                child: AdvanceWhenCard(
                                  label: l10n.advancePickupTimeLabel,
                                  month: fmt.monthShort(at),
                                  day: fmt.dayOfMonth(at),
                                  weekday: fmt.weekdayName(at),
                                  time: fmt.clockLong(at),
                                  fullDate: fmt.fullDate(at),
                                  changeLabel: l10n.rideChange,
                                  onChange: () => _pickTime(config),
                                ),
                              ),
                            if (!_routeReady)
                              _Hint(l10n.advanceChooseRouteFirst)
                            else if (at != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                l10n.advanceChooseVehicle,
                                style: AppTypography.label1.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._options(context, config, state),
                              if (selected != null &&
                                  state.options.hasValue) ...[
                                const SizedBox(height: 12),
                                _FeeNote(
                                  l10n.advanceFeeNote(
                                    fmtBaht(selected.type.fee),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      _BottomButton(state: state, onNext: () => _next(config)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _options(
    BuildContext context,
    AdvanceConfig config,
    AdvanceBookingState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return state.options.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: MassLoadingM(size: 56)),
        ),
      ],
      error: (e, _) {
        final refusal = AdvanceRefusal.from(e);
        if (refusal?.kind == AdvanceRefusalKind.disabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ref.invalidate(advanceConfigProvider);
          });
        }
        return [
          _Retry(
            text: refusal?.kind == AdvanceRefusalKind.areaNotCovered
                ? l10n.advanceErrArea
                : l10n.advanceLoadFailed,
            onRetry: () => ref
                .read(advanceBookingControllerProvider.notifier)
                .loadOptions(),
          ),
        ];
      },
      data: (options) {
        if (options.isEmpty) return [_Hint(l10n.advanceNoOptions)];
        return [
          _VehicleStrip(
            children: [
              for (final o in options)
                _VehicleCard(
                  option: o,
                  config: config,
                  selected: o.type.vehicleTypeId == state.selectedTypeId,
                  onTap: o.bookable
                      ? () => ref
                            .read(advanceBookingControllerProvider.notifier)
                            .select(o.type.vehicleTypeId)
                      : null,
                ),
            ],
          ),
        ];
      },
    );
  }
}

/// The red wave hero (Header H3): back, title, subtitle and a tilted
/// calendar page with a clock on the right showing the chosen day.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.title,
    required this.subtitle,
    required this.month,
    required this.day,
    required this.weekday,
  });

  final String title;
  final String subtitle;
  final String month;
  final int day;
  final String weekday;

  static const _artYellow = Color(0xFFFFD84D);
  static const _artBrown = Color(0xFF7F3B00);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
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
            Positioned(
              right: 24,
              top: top + 2,
              child: Transform.rotate(
                angle: 0.14,
                child: Container(
                  key: const Key('advanceHeroCalendar'),
                  width: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x47000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        color: _artYellow,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          month,
                          textAlign: TextAlign.center,
                          style: AppTypography.label2.copyWith(
                            color: _artBrown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '$day',
                        style: AppTypography.heading1.copyWith(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          weekday,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.support1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 94,
              top: top + 56,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 150, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      key: const Key('advanceBack'),
                      onTap: () => Navigator.of(context).maybePop(),
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
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.body3.copyWith(
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
}

/// Pickup → dropoff as place names only, with the app's pins and dotted
/// connector; each line opens the place search.
class _ShortRoute extends StatelessWidget {
  const _ShortRoute({
    required this.pickup,
    required this.dropoff,
    required this.pickupHint,
    required this.dropoffHint,
    required this.onEdit,
  });

  final String? pickup;
  final String? dropoff;
  final String pickupHint;
  final String dropoffHint;
  final void Function(bool pickup) onEdit;

  static const _pin = 20.0;

  Widget _line({
    required Key key,
    required String? address,
    required String hint,
    required Color pinColor,
    required VoidCallback onTap,
  }) {
    final name = address == null ? hint : advanceSplitPlace(address).$1;
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AppIcons.asset(
              AppAssets.icLocationFill,
              color: pinColor,
              width: _pin,
              height: _pin,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: address == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AdvanceCard(
    padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
    child: Column(
      children: [
        _line(
          key: const Key('advancePickup'),
          address: pickup,
          hint: pickupHint,
          pinColor: AppColors.foundationGreen500,
          onTap: () => onEdit(true),
        ),
        Row(
          children: [
            SizedBox(
              width: _pin,
              height: 10,
              child: Center(
                child: SizedBox(
                  width: 4,
                  height: 10,
                  child: CustomPaint(
                    painter: RouteDotsPainter(
                      color: AppColors.foundationGrayscale400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        _line(
          key: const Key('advanceDropoff'),
          address: dropoff,
          hint: dropoffHint,
          pinColor: AppColors.foundationRed700,
          onTap: () => onEdit(false),
        ),
      ],
    ),
  );
}

/// Before a time is set: one tappable card asking for it.
class _ChooseTime extends StatelessWidget {
  const _ChooseTime({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? AppColors.textDisabled : AppColors.primary;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.foundationGrayscale300),
      ),
      child: InkWell(
        key: const Key('advanceTimeBar'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.event_rounded, size: 22, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.label1.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// The vehicle cards in one row, the same height; they scroll sideways when
/// there are more than three.
class _VehicleStrip extends StatelessWidget {
  const _VehicleStrip({required this.children});

  final List<_VehicleCard> children;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = ((box.maxWidth - _gap * 2) / 3).clamp(96.0, 128.0);
      return SingleChildScrollView(
        key: const Key('advanceVehicleStrip'),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                SizedBox(width: width, child: children[i]),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.option,
    required this.config,
    required this.selected,
    this.onTap,
  });

  final AdvanceOption option;
  final AdvanceConfig config;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final disabled = !option.bookable;
    final t = option.type;
    final note = disabled
        ? (option.reason == 'TOO_FAR'
              ? l10n.advanceTooFarFor('${config.maxDays}')
              : l10n.advanceTooSoonFor(advanceLeadText(l10n, t.minLeadMinutes)))
        : (option.seats != null ? l10n.rideSeats(option.seats!) : null);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? AppColors.primary
                : AppColors.foundationGrayscale300,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: Key('advanceOption_${t.vehicleTypeId}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        vehicleIconFor('${t.vehicleKind} ${t.displayName}'),
                        width: 80,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '฿${fmtBaht(option.fare)}',
                      style: AppTypography.heading5.copyWith(
                        fontWeight: FontWeight.bold,
                        color: disabled
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                    ),
                    if (note != null)
                      Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.support1.copyWith(
                          color: disabled
                              ? AppColors.foundationOrange700
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grey note under the vehicles: the fee is included and the price is locked.
class _FeeNote extends StatelessWidget {
  const _FeeNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('advanceFeeNote'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.foundationGrayscale100,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body3.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({required this.state, required this.onNext});

  final AdvanceBookingState state;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final option = state.selected;
    if (option == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: AdvancePrimaryButton(
          key: const Key('advanceNext'),
          label: l10n.advanceBookVehicle(
            option.type.displayName,
            fmtBaht(option.fare),
          ),
          onPressed: onNext,
        ),
      ),
    );
  }
}

class _Closed extends StatelessWidget {
  const _Closed({required this.config});

  final AdvanceConfig config;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_available_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              config.closedTitle,
              textAlign: TextAlign.center,
              style: AppTypography.heading4,
            ),
            const SizedBox(height: 8),
            Text(
              config.closedMessage,
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
