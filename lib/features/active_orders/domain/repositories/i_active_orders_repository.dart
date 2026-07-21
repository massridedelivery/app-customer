import 'package:customer_app/features/active_orders/domain/models/active_order_item.dart';

abstract class IActiveOrdersRepository {
  /// GET /api/customer/active — all in-progress orders across verticals
  /// (ride + food + messenger), newest first. Empty list when idle.
  ///
  /// Concurrent callers are coalesced onto a single in-flight request, and a
  /// result is served from a short-lived cache without a round-trip. Pass
  /// [forceRefresh] to bypass the cache (still coalesced) when you explicitly
  /// need the latest — e.g. after a job status change.
  Future<List<ActiveOrderItem>> getActiveOrders({bool forceRefresh = false});
}
