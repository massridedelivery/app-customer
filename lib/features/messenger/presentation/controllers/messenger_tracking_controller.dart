import 'dart:async';

import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:customer_app/features/messenger/presentation/states/messenger_tracking_state.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messenger_tracking_controller.g.dart';

/// Live view of one messenger order: WS `messenger_*` status events
/// (envelope `{type, order_id, status}`, SCRUM-41 §6) + 10s polling as the
/// re-sync fallback, mirroring LiveFoodTrackingController.
@riverpod
class MessengerTrackingController extends _$MessengerTrackingController {
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  Timer? _pollingTimer;

  @override
  MessengerTrackingState build() {
    _initSocket();
    ref.onDispose(() {
      _socketSubscription?.cancel();
      _pollingTimer?.cancel();
    });
    return const MessengerTrackingState();
  }

  void _initSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.connect();
    _socketSubscription = socket.messages.listen(_handleSocketMessage);
  }

  void startTracking(String orderId) {
    state = state.copyWith(orderId: orderId, isLoading: true, error: null);
    _loadOrder(orderId);

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadOrder(orderId);
    });
  }

  Future<void> refresh() async {
    final id = state.orderId;
    if (id != null) await _loadOrder(id);
  }

  Future<void> _loadOrder(String id) async {
    try {
      final order = await ref.read(messengerRepositoryProvider).getOrder(id);
      if (state.orderId != id) return;
      state = state.copyWith(isLoading: false, order: order, error: null);

      if (order.isTerminal) {
        _pollingTimer?.cancel();
        _pollingTimer = null;
      }
    } catch (e) {
      if (state.orderId == id) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  void _handleSocketMessage(Map<String, dynamic> message) {
    final type = (message['type'] as String?)?.toLowerCase();
    if (type == null || !type.startsWith('messenger_')) return;

    final orderId = message['order_id']?.toString() ??
        message['data']?['order_id']?.toString();
    if (state.orderId == null || orderId != state.orderId) return;

    debugPrint('MessengerTrackingController: Received [$type]: $message');

    // Apply the pushed status right away, then refetch the authoritative
    // order (driver assignment, timestamps, cancel reason, …).
    final status = (message['status'] ?? message['data']?['status']) as String?;
    final current = state.order;
    if (status != null && current != null) {
      state = state.copyWith(order: current.copyWith(status: status));
    }
    _loadOrder(state.orderId!);
  }

  Future<bool> cancelOrder({String? reason}) async {
    final id = state.orderId;
    final order = state.order;
    if (id == null || order == null || !order.isCancellable) return false;

    state = state.copyWith(isCancelling: true);
    try {
      await ref.read(messengerRepositoryProvider).cancelOrder(id, reason: reason);
      await _loadOrder(id);
      state = state.copyWith(isCancelling: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isCancelling: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
