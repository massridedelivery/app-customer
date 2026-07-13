import 'dart:async';

import 'package:customer_app/features/active_orders/data/repositories/active_orders_repository_impl.dart';
import 'package:customer_app/features/active_orders/domain/models/active_order_item.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_orders_controller.g.dart';

/// Cross-vertical "what is this user doing right now?" index (SCRUM-45),
/// backed by `GET /api/customer/active`. One call covers ride + food +
/// messenger; consumers filter by [ActiveOrderItem.type].
@riverpod
class ActiveOrdersController extends _$ActiveOrdersController {
  @override
  FutureOr<List<ActiveOrderItem>> build() {
    return _fetchActiveOrders();
  }

  Future<List<ActiveOrderItem>> _fetchActiveOrders() async {
    try {
      final repository = ref.read(activeOrdersRepositoryProvider);
      return await repository.getActiveOrders();
    } catch (e) {
      debugPrint('Error in ActiveOrdersController: $e');
      // Return empty list on failure instead of crashing the UI
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchActiveOrders());
  }
}
