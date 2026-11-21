import 'package:customer_app/core/services/push_notification_service.dart';
import 'package:customer_app/features/active_orders/domain/models/active_order_item.dart';
import 'package:customer_app/features/advance_booking/domain/scheduled_ride.dart';
import 'package:flutter_test/flutter_test.dart';

String? _target(String type, [String? jobId = 'j1']) =>
    PushNotificationService.advancePushTarget({
      'type': type,
      'job_id': ?jobId,
      // What the backend sends today for all of them.
      'deeplink': '/live/j1',
    });

void main() {
  group('advance booking push routing', () {
    test('booking still ahead → the booking', () {
      for (final t in [
        'advance_booking_booked',
        'advance_booking_reminder_60',
        'advance_booking_driver_found',
        'advance_driver_changed',
        'advance_card_hold_needed',
      ]) {
        expect(_target(t), '/scheduled/j1', reason: t);
      }
    });

    test('ended → the ride receipt', () {
      expect(_target('advance_booking_no_driver'), '/ride/receipt/j1');
      expect(_target('advance_no_show'), '/ride/receipt/j1');
    });

    test('series day failed → the series screen', () {
      expect(_target('advance_series_failed', null), '/advance-series');
    });

    test('job_queued → live ride', () {
      expect(_target('job_queued'), '/live/j1');
    });

    test('other pushes and bad ids fall through', () {
      expect(_target('job_accepted'), isNull);
      expect(_target('chat_message'), isNull);
      expect(_target('advance_booking_booked', null), isNull);
      expect(_target('advance_booking_booked', ''), isNull);
      expect(_target('advance_booking_booked', 'a/b'), isNull);
      expect(PushNotificationService.advancePushTarget({}), isNull);
    });
  });

  group('ScheduledRide', () {
    final json = {
      'id': 'j1',
      'status': 'PENDING',
      'scheduled_at': '2026-11-22T00:30:00Z',
      'pickup_address': 'A',
      'dropoff_address': 'B',
      'fare': 240,
      'advance_booking_fee': 40,
      'advance_phase': 'BOOKED',
      'advance_policy': {
        'free_cancel_minutes': 60,
        'late_cancel_fee': 60,
        'wait_minutes': 10,
        'flight_number': 'TG103',
      },
    };

    test('parses the job and works out the free-cancel time', () {
      final r = ScheduledRide.fromJson(json);
      expect(r.id, 'j1');
      expect(r.fare, 240);
      expect(r.advanceFee, 40);
      expect(r.hasDriver, isFalse);
      expect(r.lateCancelFee, 60);
      expect(r.waitMinutes, 10);
      expect(r.flightNumber, 'TG103');
      expect(r.freeCancelUntil, DateTime.utc(2026, 11, 21, 23, 30));
    });

    test('free_cancel_until from the API wins; driver or reserved driver', () {
      final r = ScheduledRide.fromJson({
        ...json,
        'free_cancel_until': '2026-11-21T20:00:00Z',
        'reserved_driver_id': 'd9',
      });
      expect(r.freeCancelUntil, DateTime.utc(2026, 11, 21, 20));
      expect(r.hasDriver, isTrue);
    });

    test('no policy → no free-cancel time', () {
      final r = ScheduledRide.fromJson({'id': 'x', 'status': 'PENDING'});
      expect(r.freeCancelUntil, isNull);
      expect(r.scheduledAt, isNull);
    });

    test('cancel quote', () {
      final q = ScheduledCancelQuote.fromJson({
        'is_free': false,
        'cancellation_fee': 60,
        'reason': 'LATE_CANCEL',
      });
      expect(q.isFree, isFalse);
      expect(q.fee, 60);
      expect(q.reason, 'LATE_CANCEL');
    });
  });

  test('AdvanceSeries parses its days and last error', () {
    final s = AdvanceSeries.fromJson({
      'id': 's1',
      'status': 'ACTIVE',
      'time': '07:30',
      'weekdays': [1, 3, 5],
      'request': {'pickup_address': 'Home', 'dropoff_address': 'Office'},
      'last_error': 'TOO_SOON',
      'last_error_on': '2026-11-24',
      'upcoming': [
        {
          'job_id': 'j1',
          'date': '2026-11-23',
          'scheduled_at': '2026-11-23T00:30:00Z',
          'status': 'PENDING',
        },
      ],
    });
    expect(s.weekdays, [1, 3, 5]);
    expect(s.pickupAddress, 'Home');
    expect(s.lastErrorOn, '2026-11-24');
    expect(s.upcoming.single.jobId, 'j1');
  });

  test('an upcoming booking with no driver is not an active order', () {
    ActiveOrderItem item(Map<String, dynamic> extra) =>
        ActiveOrderItem.fromJson({'id': 'j1', 'type': 'RIDE', ...extra});
    expect(
      item({'scheduled_at': '2026-11-22T00:30:00Z'}).isUpcomingBooking,
      isTrue,
    );
    expect(
      item({
        'scheduled_at': '2026-11-22T00:30:00Z',
        'driver_id': 'd1',
      }).isUpcomingBooking,
      isFalse,
    );
    expect(item({}).isUpcomingBooking, isFalse);
    expect(item({'scheduled_at': null}).isUpcomingBooking, isFalse);
  });
}
