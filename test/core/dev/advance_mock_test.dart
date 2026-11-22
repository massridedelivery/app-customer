import 'package:customer_app/core/dev/advance_mock.dart';
import 'package:customer_app/features/advance_booking/domain/advance_config.dart';
import 'package:customer_app/features/advance_booking/domain/scheduled_ride.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://mock.invalid'))
      ..interceptors.add(AdvanceMockInterceptor());
  });

  test('config and options parse, SUV too soon within 2 hours', () async {
    final cfg = AdvanceConfig.fromJson(
      (await dio.get('/api/customer/advance-booking/config')).data,
    );
    expect(cfg.enabled, isTrue);
    expect(cfg.vehicleTypes, hasLength(3));

    final at = DateTime.now().toUtc().add(const Duration(minutes: 60));
    final res = await dio.get(
      '/api/customer/advance-booking/options',
      queryParameters: {'scheduled_at': at.toIso8601String()},
    );
    final opts = AdvanceOption.listFrom(res.data);
    expect(opts.map((o) => o.fare), [185, 235, 325]);
    expect(opts.last.bookable, isFalse);
    expect(opts.last.reason, 'TOO_SOON');
    expect(opts.first.bookable, isTrue);
  });

  test('book, list, quote, reschedule, cancel', () async {
    final at = DateTime.now().toUtc().add(const Duration(days: 1, hours: 3));
    final created = await dio.post(
      '/api/customer/jobs/schedule',
      data: {
        'scheduled_at': at.toIso8601String(),
        'vehicle_type_id': 'mock-economy',
        'pickup_address': 'A',
        'dropoff_address': 'B',
        'payment_method': 'CASH',
      },
    );
    expect(created.statusCode, 201);
    final id = created.data['id'] as String;

    final list = (await dio.get('/api/customer/jobs/scheduled')).data as List;
    final rides = list
        .map((j) => ScheduledRide.fromJson(Map<String, dynamic>.from(j)))
        .toList();
    expect(rides, hasLength(2)); // + the seeded ride with a driver
    expect(rides.where((r) => r.id == id).single.fare, 185);

    final free = ScheduledCancelQuote.fromJson(
      (await dio.get('/api/customer/jobs/scheduled/$id/cancel-quote')).data,
    );
    expect(free.isFree, isTrue);
    final paid = ScheduledCancelQuote.fromJson(
      (await dio.get(
        '/api/customer/jobs/scheduled/mock-adv-seeded/cancel-quote',
      )).data,
    );
    expect(paid.isFree, isFalse);
    expect(paid.fee, 60);

    final moved = await dio.patch(
      '/api/customer/jobs/scheduled/$id',
      data: {
        'scheduled_at': at.add(const Duration(hours: 1)).toIso8601String(),
      },
    );
    expect(moved.data['reschedules_left'], 2);

    await dio.post('/api/customer/jobs/scheduled/$id/cancel');
    final after = (await dio.get('/api/customer/jobs/scheduled')).data as List;
    expect(after, hasLength(1));
  });
}
