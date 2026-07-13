import 'dart:async';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/states/live_food_tracking_state.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'live_food_tracking_controller.g.dart';

@riverpod
class LiveFoodTrackingController extends _$LiveFoodTrackingController {
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  Timer? _pollingTimer;

  @override
  LiveFoodTrackingState build() {
    _initSocket();
    ref.onDispose(() {
      _socketSubscription?.cancel();
      _pollingTimer?.cancel();
    });
    return const LiveFoodTrackingState();
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
        state = state.copyWith(
          isLoading: false,
          orderStatus: upperStatus,
          driverId: order.driverId ?? state.driverId,
          driverName: order.driverName ?? state.driverName,
          vehiclePlate: order.vehiclePlate ?? state.vehiclePlate,
          restaurantLocation: restaurantLoc,
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
      if (lat != null && lng != null) {
        state = state.copyWith(
          driverLocation: LatLng(lat.toDouble(), lng.toDouble()),
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
