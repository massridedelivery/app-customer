import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/advance_booking/domain/scheduled_ride.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The customer's rides booked ahead (GET /api/customer/jobs/scheduled).
final scheduledRidesProvider = FutureProvider.autoDispose<List<ScheduledRide>>((
  ref,
) async {
  final list = await ref.watch(apiRepositoryProvider).getScheduledJobs();
  return list
      .whereType<Map>()
      .map((m) => ScheduledRide.fromJson(Map<String, dynamic>.from(m)))
      .toList();
});

/// `/scheduled/:id`: one ride booked ahead — pickup time, route, price, the
/// cancel policy and a cancel button. Opened from the advance booking pushes.
/// A plain first version; the designed booking screens replace it.
class ScheduledRideScreen extends ConsumerWidget {
  const ScheduledRideScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rides = ref.watch(scheduledRidesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.scheduledRideTitle, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: rides.when(
        loading: () => const Center(child: MassLoadingM(size: 72)),
        error: (e, _) => _Message(
          text: l10n.advanceLoadFailed,
          onRetry: () => ref.invalidate(scheduledRidesProvider),
        ),
        data: (list) {
          final ride = list.where((r) => r.id == jobId).firstOrNull;
          if (ride == null) {
            return _Message(
              key: const Key('scheduledRideNotFound'),
              text: l10n.scheduledRideNotFound,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(scheduledRidesProvider),
            child: _Body(ride: ride),
          );
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.ride});

  final ScheduledRide ride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dates = AppDates.of(context);
    String at(DateTime utc) => dates.dateTime(AppDates.bangkok(utc));
    final freeUntil = ride.freeCancelUntil;
    final secondary = AppTypography.body2.copyWith(
      color: AppColors.textSecondary,
    );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (ride.scheduledAt != null)
          Text(
            l10n.scheduledRidePickupAt(at(ride.scheduledAt!)),
            key: const Key('scheduledRidePickupAt'),
            style: AppTypography.heading4,
          ),
        const SizedBox(height: 6),
        Text(
          ride.hasDriver
              ? l10n.scheduledRideDriverFound
              : l10n.scheduledRideFindingDriver,
          style: AppTypography.label2.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        _Stop(icon: Icons.trip_origin_rounded, text: ride.pickupAddress),
        const SizedBox(height: 10),
        _Stop(icon: Icons.place_rounded, text: ride.dropoffAddress),
        if (ride.flightNumber != null) ...[
          const SizedBox(height: 10),
          Text(l10n.scheduledRideFlight(ride.flightNumber!), style: secondary),
        ],
        const Divider(height: 32),
        Text(
          l10n.scheduledRideFare(fmtBaht(ride.fare)),
          style: AppTypography.label1,
        ),
        if (ride.advanceFee > 0)
          Text(
            l10n.scheduledRideFeeIncluded(fmtBaht(ride.advanceFee)),
            style: secondary,
          ),
        const SizedBox(height: 12),
        if (freeUntil != null)
          Text(
            l10n.scheduledRideFreeCancelUntil(at(freeUntil)),
            style: secondary,
          ),
        if (ride.lateCancelFee > 0)
          Text(
            l10n.scheduledRideLateFee(fmtBaht(ride.lateCancelFee)),
            style: secondary,
          ),
        if ((ride.waitMinutes ?? 0) > 0)
          Text(l10n.scheduledRideWait('${ride.waitMinutes}'), style: secondary),
        const SizedBox(height: 28),
        OutlinedButton(
          key: const Key('scheduledRideCancel'),
          onPressed: () => _cancel(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(l10n.scheduledRideCancel),
        ),
      ],
    );
  }

  /// Shows what cancelling costs now (cancel-quote), then cancels on yes.
  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final api = ref.read(apiRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    ScheduledCancelQuote? quote;
    try {
      quote = ScheduledCancelQuote.fromJson(
        await api.getScheduledCancelQuote(ride.id),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.advanceLoadFailed)));
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.scheduledRideCancel),
        content: Text(
          quote!.isFree || quote.fee <= 0
              ? l10n.scheduledRideCancelFree
              : l10n.scheduledRideCancelFee(fmtBaht(quote.fee)),
          key: const Key('scheduledRideCancelQuote'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.scheduledRideKeep),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.scheduledRideCancelConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.cancelScheduledJob(ride.id);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.scheduledRideCancelled)),
      );
      ref.invalidate(scheduledRidesProvider);
      if (context.mounted) {
        context.canPop() ? context.pop() : context.go('/main');
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.scheduledRideCancelFailed)),
      );
    }
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: AppTypography.body2)),
    ],
  );
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
    ),
  );
}
