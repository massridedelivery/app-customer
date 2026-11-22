import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/advance-booking`: route, pickup time and the vehicle list with locked
/// prices (Vehicle variant A). Next: `/advance-booking/confirm`.
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.advanceScreenTitle, style: AppTypography.heading4),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: configAsync.when(
        loading: () => const Center(child: MassLoadingM(size: 72)),
        error: (_, _) => _Retry(
          text: l10n.advanceLoadFailed,
          onRetry: () => ref.invalidate(advanceConfigProvider),
        ),
        data: (config) {
          if (!config.enabled) {
            return _Closed(config: config);
          }
          _maybeAskTime();
          final at = state.scheduledAt;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    AdvanceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          AdvanceRouteLine(
                            key: const Key('advancePickup'),
                            text: home.pickupAddress?.isNotEmpty == true
                                ? home.pickupAddress!
                                : l10n.advancePickupHint,
                            isPickup: true,
                            onTap: () => _editRoute(pickup: true),
                          ),
                          const Divider(height: 12),
                          AdvanceRouteLine(
                            key: const Key('advanceDropoff'),
                            text: home.dropoffAddress?.isNotEmpty == true
                                ? home.dropoffAddress!
                                : l10n.advanceDropoffHint,
                            isPickup: false,
                            onTap: () => _editRoute(pickup: false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TimeBar(
                      text: at == null
                          ? l10n.advanceChooseTime
                          : l10n.advanceTimeBar(fmt.when(at, now: now)),
                      onTap: _routeReady ? () => _pickTime(config) : null,
                    ),
                    const SizedBox(height: 12),
                    if (!_routeReady)
                      _Hint(l10n.advanceChooseRouteFirst)
                    else if (at != null)
                      ..._options(context, config, state),
                  ],
                ),
              ),
              _BottomButton(state: state, onNext: () => _next(config)),
            ],
          );
        },
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
          for (final o in options) ...[
            _OptionRow(
              option: o,
              config: config,
              selected: o.type.vehicleTypeId == state.selectedTypeId,
              onTap: o.bookable
                  ? () => ref
                        .read(advanceBookingControllerProvider.notifier)
                        .select(o.type.vehicleTypeId)
                  : null,
            ),
            const SizedBox(height: 10),
          ],
        ];
      },
    );
  }
}

class _TimeBar extends StatelessWidget {
  const _TimeBar({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.softRedBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const Key('advanceTimeBar'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: AppColors.secondaryRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.label2.copyWith(
                    color: AppColors.secondaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.secondaryRed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
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
    final sub = disabled
        ? (option.reason == 'TOO_FAR'
              ? l10n.advanceTooFarFor('${config.maxDays}')
              : l10n.advanceTooSoonFor(advanceLeadText(l10n, t.minLeadMinutes)))
        : l10n.scheduledRideFeeIncluded(fmtBaht(t.fee));
    final textColor = disabled ? AppColors.textDisabled : AppColors.textPrimary;
    return Material(
      color: disabled ? AppColors.foundationGrayscale100 : Colors.white,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Opacity(
                opacity: disabled ? 0.4 : 1,
                child: Image.asset(
                  vehicleIconFor('${t.vehicleKind} ${t.displayName}'),
                  width: 52,
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.displayName,
                      style: AppTypography.label1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      sub,
                      style: AppTypography.caption3.copyWith(
                        color: disabled
                            ? AppColors.textDisabled
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!disabled)
                Text(
                  '฿${fmtBaht(option.fare)}',
                  style: AppTypography.heading5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
