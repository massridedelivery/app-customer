import 'dart:async';

import 'package:customer_app/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messenger_history_controller.g.dart';

/// Messenger order history (SCRUM-41). Separate from the trips
/// `/api/customer/history` feed, which is ride+food only — messenger orders
/// come from `GET /api/messenger/customer/orders`. Callers filter the full
/// list by status client-side.
@riverpod
class MessengerHistoryController extends _$MessengerHistoryController {
  @override
  FutureOr<List<MessengerOrder>> build() {
    return ref.read(messengerRepositoryProvider).getOrders();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(messengerRepositoryProvider).getOrders(),
    );
  }
}
