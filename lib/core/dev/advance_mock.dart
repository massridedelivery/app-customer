import 'package:dio/dio.dart';

/// `--dart-define=ADVANCE_MOCK=true`: answer the advance-booking API from
/// memory, for UI walkthroughs on a backend that doesn't have it yet. Off by
/// default, and a compile-time constant, so release builds tree-shake it.
const bool kAdvanceMock = bool.fromEnvironment('ADVANCE_MOCK');

/// With [kAdvanceMock]: the admin has advance booking switched off.
const bool kAdvanceMockClosed = bool.fromEnvironment('ADVANCE_MOCK_CLOSED');

/// Answers only the advance-booking paths; every other request goes on to the
/// real backend. Shapes follow the backend's (main) and the app's parsers.
class AdvanceMockInterceptor extends Interceptor {
  AdvanceMockInterceptor() {
    _seed();
  }

  static const _fee = 40.0;
  static const _lateFee = 60.0;
  static const _freeCancel = 60;

  static const _types = [
    {
      'vehicle_type_id': 'mock-economy',
      'display_name': 'Economy',
      'vehicle_kind': 'car',
      'vehicle_class': 'ride',
      'min_lead_minutes': 30,
      'ride_fare': 145.0,
      'seats': 4,
    },
    {
      'vehicle_type_id': 'mock-comfort',
      'display_name': 'Comfort',
      'vehicle_kind': 'car',
      'vehicle_class': 'ride',
      'min_lead_minutes': 30,
      'ride_fare': 195.0,
      'seats': 4,
    },
    {
      'vehicle_type_id': 'mock-suv',
      'display_name': 'SUV 6 ที่นั่ง',
      'vehicle_kind': 'car',
      'vehicle_class': 'ride',
      'min_lead_minutes': 120,
      'ride_fare': 285.0,
      'seats': 6,
    },
  ];

  final List<Map<String, dynamic>> _jobs = [];
  int _next = 1;

  void _seed() {
    // Tomorrow 08:00 Bangkok, already taken by a driver.
    final bkk = DateTime.now().toUtc().add(const Duration(hours: 7));
    final at = DateTime.utc(bkk.year, bkk.month, bkk.day + 1, 1);
    _jobs.add(
      _job(
        id: 'mock-adv-seeded',
        type: _types[1],
        at: at,
        pickup: 'คอนโดลุมพินี พระราม 9',
        dropoff: 'ออฟฟิศ อโศก',
        payment: 'PROMPTPAY',
      )..addAll({
        'status': 'ACCEPTED',
        'driver_id': 'mock-driver-1',
        'reserved_driver_id': 'mock-driver-1',
        'advance_phase': 'CLAIMED',
        'reschedules_left': 0,
        'driver_info': {
          'full_name': 'สมชาย ใจดี',
          'vehicle_plate': 'กข 1234',
          'vehicle_model': 'Toyota Altis',
          'vehicle_color': 'สีขาว',
          'vehicle_type_display_name': 'Comfort',
        },
      }),
    );
  }

  Map<String, dynamic> _job({
    required String id,
    required Map<String, Object> type,
    required DateTime at,
    required String pickup,
    required String dropoff,
    required String payment,
    String? flight,
  }) {
    final rideFare = type['ride_fare'] as double;
    return {
      'id': id,
      'status': 'PENDING',
      'scheduled_at': at.toIso8601String(),
      'is_scheduled': true,
      'pickup_address': pickup,
      'dropoff_address': dropoff,
      'fare': rideFare + _fee,
      'advance_booking_fee': _fee,
      'payment_method': payment,
      'vehicle_type_id': type['vehicle_type_id'],
      'vehicle_type_display_name': type['display_name'],
      'driver_id': '',
      'reserved_driver_id': '',
      'advance_phase': 'BOOKED',
      'reschedules_left': 3,
      'free_cancel_until': at
          .subtract(const Duration(minutes: _freeCancel))
          .toIso8601String(),
      'advance_policy': {
        'fee': _fee,
        'late_cancel_fee': _lateFee,
        'free_cancel_minutes': _freeCancel,
        'wait_minutes': flight == null ? 10 : 45,
        'min_lead_minutes': type['min_lead_minutes'],
        'flight_number': ?flight,
      },
    };
  }

  Map<String, Object> _type(Object? id) => _types.firstWhere(
    (t) => t['vehicle_type_id'] == id,
    orElse: () => _types.first,
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.uri.path;
    final m = options.method.toUpperCase();
    Response<dynamic> ok(Object? data, [int status = 200]) =>
        Response(requestOptions: options, statusCode: status, data: data);

    if (path.endsWith('/api/customer/advance-booking/config')) {
      return handler.resolve(ok(_config()));
    }
    if (path.endsWith('/api/customer/advance-booking/options')) {
      return handler.resolve(ok(_options(options.queryParameters)));
    }
    if (path.endsWith('/api/customer/advance-series')) {
      return handler.resolve(ok(const <Object>[]));
    }
    if (path.endsWith('/api/customer/jobs/schedule') && m == 'POST') {
      final body = options.data is Map
          ? Map<String, dynamic>.from(options.data as Map)
          : <String, dynamic>{};
      final at =
          DateTime.tryParse('${body['scheduled_at']}')?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(hours: 2));
      final flight = '${body['flight_number'] ?? ''}'.trim().toUpperCase();
      final job = _job(
        id: 'mock-adv-${_next++}',
        type: _type(body['vehicle_type_id']),
        at: at,
        pickup: '${body['pickup_address'] ?? ''}',
        dropoff: '${body['dropoff_address'] ?? ''}',
        payment: '${body['payment_method'] ?? 'CASH'}',
        flight: flight.isEmpty ? null : flight,
      );
      _jobs.add(job);
      return handler.resolve(ok(job, 201));
    }
    if (path.endsWith('/api/customer/jobs/scheduled') && m == 'GET') {
      final list = [..._jobs]
        ..sort(
          (a, b) => '${a['scheduled_at']}'.compareTo('${b['scheduled_at']}'),
        );
      return handler.resolve(ok(list));
    }
    final match = RegExp(
      r'/api/customer/jobs/scheduled/([^/]+)(/cancel-quote|/cancel)?$',
    ).firstMatch(path);
    if (match != null) {
      final id = match.group(1)!;
      final tail = match.group(2) ?? '';
      final i = _jobs.indexWhere((j) => j['id'] == id);
      if (i < 0) {
        return handler.resolve(ok({'error': 'job not found'}, 404));
      }
      final job = _jobs[i];
      final hasDriver = '${job['driver_id']}'.isNotEmpty;
      if (tail == '/cancel-quote') {
        return handler.resolve(
          ok(
            hasDriver
                ? {
                    'is_free': false,
                    'cancellation_fee': _lateFee,
                    'reason': 'LATE_CANCEL',
                  }
                : {
                    'is_free': true,
                    'cancellation_fee': 0,
                    'reason': 'NO_DRIVER_YET',
                  },
          ),
        );
      }
      if (tail == '/cancel' && m == 'POST') {
        _jobs.removeAt(i);
        return handler.resolve(
          ok({
            'message': 'cancelled',
            'cancellation_fee': hasDriver ? _lateFee : 0,
          }),
        );
      }
      if (tail.isEmpty && m == 'PATCH') {
        final body = options.data is Map ? options.data as Map : const {};
        final at = DateTime.tryParse('${body['scheduled_at']}')?.toUtc();
        if (at != null) {
          job['scheduled_at'] = at.toIso8601String();
          job['free_cancel_until'] = at
              .subtract(const Duration(minutes: _freeCancel))
              .toIso8601String();
        }
        job['reschedules_left'] = 2;
        return handler.resolve(ok({'job': job, 'reschedules_left': 2}));
      }
    }
    handler.next(options);
  }

  Map<String, Object> _config() => {
    'enabled': !kAdvanceMockClosed,
    'closed_title': 'จองล่วงหน้ายังไม่เปิดให้บริการ',
    'closed_message': 'เรากำลังเตรียมระบบจองล่วงหน้า เปิดให้ใช้เร็ว ๆ นี้',
    'min_lead_minutes': 30,
    'max_days': 7,
    'slot_minutes': 5,
    'free_cancel_minutes': _freeCancel,
    'wait_minutes': 10,
    'driver_late_minutes': 10,
    'cash_allowed': true,
    'max_reschedules': 3,
    'airport_wait_minutes': 45,
    'recurring_enabled': false,
    'max_series': 3,
    'messenger_enabled': false,
    'preauth_enabled': false,
    'vehicle_types': [
      for (final t in _types)
        {
          'vehicle_type_id': t['vehicle_type_id']!,
          'display_name': t['display_name']!,
          'vehicle_kind': t['vehicle_kind']!,
          'vehicle_class': t['vehicle_class']!,
          'advance_booking_fee': _fee,
          'min_lead_minutes': t['min_lead_minutes']!,
          'late_cancel_fee': _lateFee,
          'search_starts_minutes_before': 60,
        },
    ],
  };

  Map<String, Object> _options(Map<String, dynamic> q) {
    final at =
        DateTime.tryParse('${q['scheduled_at']}')?.toUtc() ??
        DateTime.now().toUtc();
    final lead = at.difference(DateTime.now().toUtc()).inMinutes;
    return {
      'scheduled_at': at.toIso8601String(),
      'distance_km': 32.4,
      'duration_min': 35,
      'options': [
        for (final t in _types)
          {
            'vehicle_type_id': t['vehicle_type_id']!,
            'display_name': t['display_name']!,
            'vehicle_kind': t['vehicle_kind']!,
            'vehicle_class': t['vehicle_class']!,
            'seats': t['seats']!,
            'ride_fare': t['ride_fare']!,
            'advance_booking_fee': _fee,
            'fare': (t['ride_fare'] as double) + _fee,
            'late_cancel_fee': _lateFee,
            'min_lead_minutes': t['min_lead_minutes']!,
            'bookable': lead >= (t['min_lead_minutes'] as int),
            if (lead < (t['min_lead_minutes'] as int)) 'reason': 'TOO_SOON',
            'free_cancel_until': at
                .subtract(const Duration(minutes: _freeCancel))
                .toIso8601String(),
          },
      ],
    };
  }
}
