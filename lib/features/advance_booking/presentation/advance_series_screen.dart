import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/advance_booking/domain/scheduled_ride.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The customer's repeating bookings (GET /api/customer/advance-series).
final advanceSeriesProvider = FutureProvider.autoDispose<List<AdvanceSeries>>((
  ref,
) async {
  final list = await ref.watch(apiRepositoryProvider).getAdvanceSeries();
  return list
      .whereType<Map>()
      .map((m) => AdvanceSeries.fromJson(Map<String, dynamic>.from(m)))
      .toList();
});

/// `/advance-series`: the repeating bookings, each with its time, route, the
/// days already booked and the latest day that could not be booked. Opened
/// from the advance_series_failed push. A plain first version; the designed
/// screens replace it.
class AdvanceSeriesScreen extends ConsumerWidget {
  const AdvanceSeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final series = ref.watch(advanceSeriesProvider);
    final secondary = AppTypography.caption4.copyWith(
      color: AppColors.textSecondary,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.advanceSeriesTitle, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: series.when(
        loading: () => const Center(child: MassLoadingM(size: 72)),
        error: (e, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(advanceSeriesProvider),
            child: Text(l10n.advanceLoadFailed),
          ),
        ),
        data: (list) => list.isEmpty
            ? Center(
                child: Text(
                  l10n.advanceSeriesEmpty,
                  key: const Key('advanceSeriesEmpty'),
                  style: secondary,
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(advanceSeriesProvider),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = list[i];
                    return Container(
                      key: Key('advanceSeries-${s.id}'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.time,
                                  style: AppTypography.heading5,
                                ),
                              ),
                              if (s.status == 'PAUSED')
                                Text(
                                  l10n.advanceSeriesPaused,
                                  style: secondary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(s.pickupAddress, style: AppTypography.body2),
                          Text(s.dropoffAddress, style: AppTypography.body2),
                          const SizedBox(height: 6),
                          Text(
                            l10n.advanceSeriesBooked('${s.upcoming.length}'),
                            style: secondary,
                          ),
                          if (s.lastErrorOn != null)
                            Text(
                              l10n.advanceSeriesLastError(s.lastErrorOn!),
                              style: secondary.copyWith(
                                color: AppColors.semanticErrorFgHigh,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
