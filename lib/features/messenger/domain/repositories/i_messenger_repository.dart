import 'package:customer_app/features/messenger/domain/models/messenger_estimate.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_vehicle_type.dart';

abstract class IMessengerRepository {
  /// GET /api/vehicle-types filtered to active messenger vehicles.
  Future<List<MessengerVehicleType>> getMessengerVehicleTypes();

  /// POST /api/messenger/customer/estimate
  Future<MessengerEstimate> estimate({
    required String vehicleTypeId,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String packageSizeTier,
    required double packageWeightKg,
    double? packageLengthCm,
    double? packageWidthCm,
    double? packageHeightCm,
    String? promoCode,
  });

  /// POST /api/messenger/customer/orders → 201 Order (PENDING)
  Future<MessengerOrder> createOrder({
    required String vehicleTypeId,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String packageSizeTier,
    required double packageWeightKg,
    required String paymentMethod,
    String? pickupAddress,
    String? dropoffAddress,
    String? recipientName,
    String? recipientPhone,
    String? notes,
    double? packageLengthCm,
    double? packageWidthCm,
    double? packageHeightCm,
    double? codAmount,
    String? promoCode,
  });

  /// GET /api/messenger/customer/orders — the customer's messenger orders,
  /// newest first, all statuses (not paginated in phase 1).
  Future<List<MessengerOrder>> getOrders();

  /// GET /api/messenger/customer/orders/{id}
  Future<MessengerOrder> getOrder(String id);

  /// POST /api/messenger/customer/orders/{id}/cancel (PENDING/ACCEPTED only)
  Future<void> cancelOrder(String id, {String? reason});

  /// POST /api/messenger/customer/orders/{id}/review — rating 1..5 required,
  /// optional comment. Only valid after DELIVERED (400 otherwise); 409 if the
  /// order was already reviewed.
  Future<void> reviewOrder(String id, {required int rating, String? comment});

  /// GET /api/messenger/customer/orders/{id}/chat — Message[] newest first,
  /// paginated via `limit` (≤100) and `before` cursor.
  Future<List<dynamic>> getChat(String id, {int limit = 50, String? before});

  /// POST /api/messenger/customer/orders/{id}/chat — usable once a driver
  /// has accepted (before that there is no counterparty).
  Future<void> sendChatMessage(
    String id, {
    required String text,
    String msgType = 'text',
    String? fileKey,
  });
}
