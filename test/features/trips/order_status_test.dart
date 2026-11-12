import 'package:customer_app/core/services/push_notification_service.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('food statuses map to completed / cancelled in history', () {
    for (final s in ['COMPLETED', 'SUCCESS', 'DELIVERED', 'delivered']) {
      expect(isCompletedOrderStatus(s), isTrue, reason: s);
      expect(isCancelledOrderStatus(s), isFalse, reason: s);
    }
    for (final s in [
      'CANCELLED',
      'FAILED',
      'RESTAURANT_REJECTED',
      'FAILED_DISPATCH',
    ]) {
      expect(isCancelledOrderStatus(s), isTrue, reason: s);
      expect(isCompletedOrderStatus(s), isFalse, reason: s);
    }
    for (final s in ['PLACED', 'PREPARING', 'DRIVER_ASSIGNED', 'PENDING']) {
      expect(
        isCompletedOrderStatus(s) || isCancelledOrderStatus(s),
        isFalse,
        reason: s,
      );
    }
  });

  group('food receipt push target', () {
    test('a food push (no type, or order_delivered) opens the order', () {
      expect(
        PushNotificationService.foodReceiptTarget('/order/receipt/abc', null),
        '/trip/abc?type=FOOD',
      );
      expect(
        PushNotificationService.foodReceiptTarget(
          '/order/receipt/abc',
          'order_delivered',
        ),
        '/trip/abc?type=FOOD',
      );
    });

    test('a messenger push and other links are left alone', () {
      expect(
        PushNotificationService.foodReceiptTarget(
          '/order/receipt/abc',
          'messenger_delivered',
        ),
        isNull,
      );
      expect(
        PushNotificationService.foodReceiptTarget(
          '/food-order/tracking/a',
          null,
        ),
        isNull,
      );
      expect(
        PushNotificationService.foodReceiptTarget('/order/receipt/', null),
        isNull,
      );
    });
  });
}
