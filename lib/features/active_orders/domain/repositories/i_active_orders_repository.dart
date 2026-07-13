import 'package:customer_app/features/active_orders/domain/models/active_order_item.dart';

abstract class IActiveOrdersRepository {
  /// GET /api/customer/active — all in-progress orders across verticals
  /// (ride + food + messenger), newest first. Empty list when idle.
  Future<List<ActiveOrderItem>> getActiveOrders();
}
