import 'dart:async';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/states/live_food_tracking_state.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'live_food_tracking_controller.g.dart';

@riverpod
class LiveFoodTrackingController extends _$LiveFoodTrackingController {
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  Timer? _pollingTimer;
  AppLifecycleListener? _lifecycleListener;

  @override
  LiveFoodTrackingState build() {
    _initSocket();
    // Re-sync the instant the app returns to the foreground — see [_onResume].
    _lifecycleListener = AppLifecycleListener(onResume: _onResume);
    ref.onDispose(() {
      _socketSubscription?.cancel();
      _pollingTimer?.cancel();
      _lifecycleListener?.dispose();
    });
    return const LiveFoodTrackingState();
  }

  /// App returned to the foreground. WS frames pushed while backgrounded are
  /// gone (socket suspended, no replay on reconnect), so refetch the order right
  /// away instead of waiting for the next 10s poll — otherwise an order the
  /// rider delivered while the user was in another app leaves the screen stuck.
  void _onResume() {
    final id = state.orderId;
    if (id == null) return;
    if (_isTerminalStatus(state.orderStatus)) return;
    _loadOrderDetail(id);
  }

  void _initSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.connect();

    _socketSubscription = socket.messages.listen((message) {
      _handleSocketMessage(message);
    });
  }

  bool _isTerminalStatus(String status) {
    final s = status.toUpperCase();
    return s == 'CANCELLED' ||
        s == 'RESTAURANT_REJECTED' ||
        s == 'COMPLETED' ||
        s == 'DELIVERED';
  }

  void startTracking(String orderId) {
    state = state.copyWith(orderId: orderId, isLoading: true, error: null);
    _loadOrderDetail(orderId);

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadOrderDetail(orderId);
    });
  }

  Future<void> _loadOrderDetail(String id) async {
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      final order = await repo.getOrderDetail(id);

      LatLng? restaurantLoc = state.restaurantLocation;
      if (restaurantLoc == null) {
        try {
          final restaurant = await repo.getRestaurantProfile(order.restaurantId);
          restaurantLoc = LatLng(restaurant.lat, restaurant.lng);
        } catch (e) {
          debugPrint('Failed to load restaurant profile in tracking controller: $e');
        }
      }

      if (state.orderId == id) {
        final upperStatus = order.status.toUpperCase();
        // ETA via REST (dev14): the order now carries a live estimate too, not
        // just the socket. Prefer it when present; else keep the socket value.
        // omitempty — absent (not 0) means no estimate, so leave ETA untouched.
        DateTime? etaFromOrder;
        final at = order.arriveAt;
        if (at != null && at.isNotEmpty) {
          etaFromOrder = DateTime.tryParse(at)?.toLocal();
        }
        etaFromOrder ??= order.etaMin != null
            ? DateTime.now().add(Duration(minutes: order.etaMin!))
            : null;
        state = state.copyWith(
          isLoading: false,
          orderStatus: upperStatus,
          driverId: order.driverId ?? state.driverId,
          driverName: order.driverName ?? state.driverName,
          vehiclePlate: order.vehiclePlate ?? state.vehiclePlate,
          restaurantLocation: restaurantLoc,
          etaArriveAt: etaFromOrder ?? state.etaArriveAt,
          order: order,
        );

        if (_isTerminalStatus(upperStatus)) {
          _pollingTimer?.cancel();
          _pollingTimer = null;
        }
      }
    } catch (e) {
      if (state.orderId == id) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  /// Arrival time from a driver-location payload: prefers absolute `arrive_at`
  /// (ISO8601); else derives from `eta_min` (now + N min). Null if neither.
  DateTime? _parseEta(Map<String, dynamic> data) {
    final iso = data['arrive_at'] as String?;
    if (iso != null && iso.isNotEmpty) {
      return DateTime.tryParse(iso)?.toLocal();
    }
    final etaMin =
        (data['eta_min'] ?? data['eta_minutes'] ?? data['eta']) as num?;
    if (etaMin != null) {
      return DateTime.now().add(Duration(minutes: etaMin.round()));
    }
    return null;
  }

  void _handleSocketMessage(Map<String, dynamic> message) {
    final type = (message['type'] as String?)?.toLowerCase();
    final orderId = message['order_id']?.toString() ??
        message['orderId']?.toString() ??
        message['data']?['order_id']?.toString() ??
        message['data']?['orderId']?.toString();

    if (state.orderId == null || orderId != state.orderId) {
      return;
    }

    debugPrint(
      'LiveFoodTrackingController: Received message [$type]: $message',
    );

    if (type == 'driver_location' || type == 'driverlocation') {
      final data = message['data'] as Map<String, dynamic>? ?? message;
      final lat = (data['lat'] ?? data['latitude']) as num?;
      final lng = (data['lng'] ?? data['longitude']) as num?;
      // Server-computed food arrival time — pushed with the location so the
      // client never calls a routing API. Prefer absolute `arrive_at`; fall
      // back to `eta_min` (now + N). Optional: kept when absent.
      final arriveAt = _parseEta(data);
      if (lat != null && lng != null) {
        // ETA keys are sent every frame while there's an ETA and vanish when
        // there's none — set directly so absent (null) hides the ETA rather
        // than leaving a stale countdown (SCRUM-76). Never default to 0.
        state = state.copyWith(
          driverLocation: LatLng(lat.toDouble(), lng.toDouble()),
          etaArriveAt: arriveAt,
        );
      }
      return;
    }

    if (type == 'order_cancelled_oos' || type == 'items_oos') {
      _loadOrderDetail(state.orderId!);
      return;
    }

    final status =
        message['status']?.toString() ??
        message['order']?['status']?.toString();
    if (status != null) {
      final upperStatus = status.toUpperCase();
      state = state.copyWith(orderStatus: upperStatus);
      if (_isTerminalStatus(upperStatus)) {
        _pollingTimer?.cancel();
        _pollingTimer = null;
      }
    }

    final orderData = message['order'] as Map<String, dynamic>?;
    if (orderData != null) {
      try {
        final order = FoodOrderModel.fromJson(orderData);
        final upperStatus = order.status.toUpperCase();
        state = state.copyWith(
          orderStatus: upperStatus,
          driverId: order.driverId ?? state.driverId,
          driverName: order.driverName ?? state.driverName,
          vehiclePlate: order.vehiclePlate ?? state.vehiclePlate,
          order: order,
        );
        if (_isTerminalStatus(upperStatus)) {
          _pollingTimer?.cancel();
          _pollingTimer = null;
        }
      } catch (e) {
        debugPrint(
          'LiveFoodTrackingController: Failed to parse order from WS $e',
        );
      }
    }

    if (type == 'driver_assigned') {
      final driverId =
          message['driver_id']?.toString() ?? message['driverId']?.toString();
      final driverName = message['driver_name'] ?? message['driverName'];
      final plate = message['vehicle_plate'] ?? message['vehiclePlate'];
      state = state.copyWith(
        orderStatus: 'DRIVER_ASSIGNED',
        driverId: driverId ?? state.driverId,
        driverName: driverName ?? state.driverName,
        vehiclePlate: plate ?? state.vehiclePlate,
      );
    }
  }

  Future<void> cancelActiveOrder() async {
    final id = state.orderId;
    if (id == null) return;
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      await repo.cancelOrder(id);
      state = state.copyWith(orderStatus: 'CANCELLED');
      _pollingTimer?.cancel();
      _pollingTimer = null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}
