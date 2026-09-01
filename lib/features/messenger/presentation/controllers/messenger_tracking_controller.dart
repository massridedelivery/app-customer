import 'dart:async';

import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:customer_app/features/messenger/presentation/states/messenger_tracking_state.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messenger_tracking_controller.g.dart';

/// Live view of one messenger order: WS `messenger_*` status events
/// (envelope `{type, order_id, status}`, SCRUM-41 §6) + 10s polling as the
/// re-sync fallback, mirroring LiveFoodTrackingController.
@riverpod
class MessengerTrackingController extends _$MessengerTrackingController {
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  StreamSubscription<void>? _reconnectSubscription;
  Timer? _pollingTimer;
  AppLifecycleListener? _lifecycleListener;

  @override
  MessengerTrackingState build() {
    _initSocket();
    // Re-sync the instant the app returns to the foreground — see [_onResume].
    _lifecycleListener = AppLifecycleListener(onResume: _onResume);
    ref.onDispose(() {
      _socketSubscription?.cancel();
      _reconnectSubscription?.cancel();
      _pollingTimer?.cancel();
      _lifecycleListener?.dispose();
    });
    return const MessengerTrackingState();
  }

  /// App returned to the foreground. WS frames pushed while backgrounded are
  /// gone (socket suspended, no replay on reconnect), so refetch the order right
  /// away instead of waiting for the next 10s poll — otherwise a delivery the
  /// rider finished while the user was in another app leaves the screen stuck.
  void _onResume() {
    final id = state.orderId;
    if (id == null) return;
    final order = state.order;
    if (order != null && order.isTerminal) return;
    _loadOrder(id);
  }

  void _initSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.connect();
    _socketSubscription = socket.messages.listen(_handleSocketMessage);
    // Missed frames during a mid-session drop are gone (no replay) — refetch the
    // order the moment the socket comes back so status/driver updates that
    // landed during the gap show immediately, not at the next 10s poll.
    _reconnectSubscription = socket.reconnected.listen((_) {
      final id = state.orderId;
      if (id == null) return;
      if (state.order?.isTerminal ?? false) return;
      _loadOrder(id);
    });
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
      state = state.copyWith(
        isLoading: false,
        order: order,
        error: null,
        awaitingPromptPay: _computeAwaitingPromptPay(order),
      );

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

  /// Whether to show the "scan the driver's QR" notice now: a sender-pays
  /// PromptPay order (dispatched unpaid) whose driver has reached pickup and
  /// whose fee is still owed. QR is scanned in person at the driver — the app
  /// never opens its own QR. Recomputed on every load, so it clears itself the
  /// moment payment lands (PAID).
  bool _computeAwaitingPromptPay(MessengerOrder order) {
    return !order.isTerminal &&
        order.isSenderPromptPayUnpaid &&
        order.isDriverAtPickup;
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
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isCancelling: false,
        // A paid order can't be cancelled in-app (PromptPay refunds are manual
        // via admin) — point the user at support instead of a raw 409 (dev14).
        error: msg == 'ORDER_ALREADY_PAID'
            ? 'ออเดอร์นี้ชำระเงินแล้ว ยกเลิกในแอปไม่ได้ กรุณาติดต่อฝ่ายบริการลูกค้าเพื่อขอคืนเงิน'
            : msg,
      );
      return false;
    }
  }

  /// Switch a still-unpaid PromptPay order to cash — the customer's fallback for
  /// a dead battery / no signal. The driver then collects cash at the rider.
  /// Refetches so the "scan the driver's QR" notice clears once the method flips.
  Future<bool> switchToCash() async {
    final id = state.orderId;
    final order = state.order;
    if (id == null || order == null || order.isPaid) return false;
    try {
      await ref.read(messengerRepositoryProvider).switchToCash(id);
      await _loadOrder(id);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        error: msg == 'ORDER_ALREADY_PAID' ? 'ออเดอร์นี้ชำระเงินแล้ว' : msg,
      );
      return false;
    }
  }
}
