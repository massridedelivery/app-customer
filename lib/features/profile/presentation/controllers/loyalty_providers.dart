import 'package:customer_app/features/profile/data/datasources/loyalty_remote_data_source.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Points balance & rules. autoDispose so every visit reads fresh numbers —
/// points change after a finished trip, a cancel (refund) or a redeem.
final loyaltySummaryProvider = FutureProvider.autoDispose<LoyaltySummary>((
  ref,
) async {
  final json = await ref.watch(loyaltyRemoteDataSourceProvider).getSummary();
  return LoyaltySummary.fromJson(json);
});

/// แลกคะแนน list, with this customer's balance and per-reward eligibility.
final rewardsProvider = FutureProvider.autoDispose<RewardList>((ref) async {
  final json = await ref.watch(loyaltyRemoteDataSourceProvider).getRewards();
  return RewardList.fromJson(json);
});

/// คูปองของฉัน, one list per status tab (ACTIVE / USED / EXPIRED).
final vouchersProvider = FutureProvider.autoDispose
    .family<List<Voucher>, String>((ref, status) async {
      final json = await ref
          .watch(loyaltyRemoteDataSourceProvider)
          .getVouchers(status: status);
      final raw = json['items'];
      return raw is List
          ? raw
                .whereType<Map>()
                .map((m) => Voucher.fromJson(Map<String, dynamic>.from(m)))
                .toList()
          : const [];
    });

/// Points earned on order [orderId] (a finished trip), from the points
/// history; 0 when none (not earned yet, below the minimum, …).
final pointsEarnedForOrderProvider = FutureProvider.autoDispose
    .family<int, String>((ref, orderId) async {
      final json = await ref
          .watch(loyaltyRemoteDataSourceProvider)
          .getPoints(limit: 100);
      final raw = json['transactions'] ?? json['items'] ?? const [];
      if (raw is! List) return 0;
      var earned = 0;
      for (final m in raw.whereType<Map>()) {
        final e = PointsEntry.fromJson(Map<String, dynamic>.from(m));
        if (e.type == 'EARN' && e.orderId == orderId) earned += e.points;
      }
      return earned;
    });

/// After a redeem: every screen showing points or vouchers reads again.
void refreshLoyalty(WidgetRef ref) {
  ref.invalidate(loyaltySummaryProvider);
  ref.invalidate(rewardsProvider);
  ref.invalidate(vouchersProvider);
  ref.invalidate(pointsHistoryProvider);
}

class PointsHistoryState {
  const PointsHistoryState({
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
  });

  final List<PointsEntry> items;
  final bool hasMore;
  final bool loadingMore;
}

/// Points history, paged by offset for infinite scroll.
class PointsHistoryController extends AsyncNotifier<PointsHistoryState> {
  static const pageSize = 20;

  @override
  Future<PointsHistoryState> build() async {
    final page = await _fetch(0);
    return PointsHistoryState(items: page, hasMore: page.length >= pageSize);
  }

  Future<List<PointsEntry>> _fetch(int offset) async {
    final json = await ref
        .read(loyaltyRemoteDataSourceProvider)
        .getPoints(limit: pageSize, offset: offset);
    final raw = json['items'] ?? json['transactions'] ?? json['data'];
    return raw is List
        ? raw
              .whereType<Map>()
              .map((m) => PointsEntry.fromJson(Map<String, dynamic>.from(m)))
              .toList()
        : const [];
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      PointsHistoryState(items: current.items, hasMore: true, loadingMore: true),
    );
    try {
      final page = await _fetch(current.items.length);
      final seen = {for (final e in current.items) e.id};
      final fresh = page.where((e) => !seen.contains(e.id)).toList();
      state = AsyncData(
        PointsHistoryState(
          items: [...current.items, ...fresh],
          // A page with nothing new (a backend that ignores `offset` sends
          // the first page again) ends the list instead of looping.
          hasMore: page.length >= pageSize && fresh.isNotEmpty,
        ),
      );
    } catch (_) {
      // Keep what we have; reaching the end again retries.
      state = AsyncData(
        PointsHistoryState(items: current.items, hasMore: current.hasMore),
      );
    }
  }
}

final pointsHistoryProvider =
    AsyncNotifierProvider.autoDispose<
      PointsHistoryController,
      PointsHistoryState
    >(PointsHistoryController.new);

/// A voucher / promo code the customer chose with "ใช้เลย", waiting for the
/// next booking screen of [service] (RIDE / MESSENGER) to pre-fill it.
class PendingPromoCode {
  const PendingPromoCode(this.code, this.service);

  final String code;
  final String service;
}

class PendingPromoCodeController extends Notifier<PendingPromoCode?> {
  @override
  PendingPromoCode? build() => null;

  void set(String code, String service) =>
      state = PendingPromoCode(code, service);

  /// Hands the code to the booking screen of [service] once.
  String? take(String service) {
    final pending = state;
    if (pending == null || pending.service != service) return null;
    state = null;
    return pending.code;
  }
}

final pendingPromoCodeProvider =
    NotifierProvider<PendingPromoCodeController, PendingPromoCode?>(
      PendingPromoCodeController.new,
    );
