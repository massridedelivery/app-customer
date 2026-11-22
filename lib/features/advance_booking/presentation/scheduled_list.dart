import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/advance_booking/domain/advance_format.dart';
import 'package:customer_app/features/advance_booking/domain/advance_slots.dart';
import 'package:customer_app/features/advance_booking/domain/scheduled_ride.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_common.dart';
import 'package:customer_app/features/advance_booking/presentation/scheduled_ride_screen.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bookings grouped by their Bangkok pickup day, soonest first. A booking
/// without a time goes last.
List<({DateTime? day, List<ScheduledRide> rides})> groupScheduledByDay(
  List<ScheduledRide> rides,
) {
  final sorted = [...rides]
    ..sort((a, b) {
      final x = a.scheduledAt, y = b.scheduledAt;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });
  final out = <({DateTime? day, List<ScheduledRide> rides})>[];
  for (final r in sorted) {
    final at = r.scheduledAt;
    DateTime? day;
    if (at != null) {
      final w = AdvanceSlots.toBangkok(at);
      day = DateTime.utc(w.year, w.month, w.day);
    }
    if (out.isNotEmpty && out.last.day == day) {
      out.last.rides.add(r);
    } else {
      out.add((day: day, rides: [r]));
    }
  }
  return out;
}

/// The orders screen's "จองล่วงหน้า" list (List variant A).
class ScheduledBookingsList extends ConsumerWidget {
  const ScheduledBookingsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rides = ref.watch(scheduledRidesProvider);
    final fmt = advanceFormatOf(context);
    final now = DateTime.now();
    return rides.when(
      loading: () => const Center(child: MassLoadingM(size: 72)),
      error: (_, _) => ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(l10n.advanceLoadFailed)),
          Center(
            child: TextButton(
              onPressed: () => ref.invalidate(scheduledRidesProvider),
              child: Text(l10n.retry),
            ),
          ),
        ],
      ),
      data: (list) {
        if (list.isEmpty) {
          final enabled = ref.watch(advanceConfigProvider).value?.enabled;
          return ListView(
            key: const Key('scheduledListEmpty'),
            children: [
              const SizedBox(height: 80),
              Center(
                child: Text(
                  l10n.advanceListEmpty,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (enabled == true)
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/advance-booking'),
                    child: Text(l10n.advanceBookNew),
                  ),
                ),
            ],
          );
        }
        final groups = groupScheduledByDay(list);
        return ListView(
          key: const Key('scheduledList'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final g in groups) ...[
              if (g.day != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: Text(
                    fmt.dayHeading(AdvanceSlots.fromBangkok(g.day!), now: now),
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              for (final r in g.rides) ...[
                _BookingCard(ride: r, fmt: fmt, now: now),
                const SizedBox(height: 10),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.ride,
    required this.fmt,
    required this.now,
  });

  final ScheduledRide ride;
  final AdvanceFormat fmt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final at = ride.scheduledAt;
    final freeUntil = ride.freeCancelUntil;
    final sub = [
      ?ride.vehicleName,
      '฿${fmtBaht(ride.fare)}',
      if (freeUntil != null)
        l10n.scheduledRideFreeCancelUntil(fmt.clock(freeUntil)),
    ].join(' · ');
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.foundationGrayscale300),
      ),
      child: InkWell(
        key: Key('scheduledCard_${ride.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/scheduled/${ride.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      at == null ? '-' : fmt.clock(at),
                      style: AppTypography.heading4,
                    ),
                  ),
                  AdvanceStatusChip(ride: ride),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${ride.pickupAddress} → ${ride.dropoffAddress}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body2,
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: AppTypography.caption3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
