import 'dart:convert';
import 'dart:typed_data';

import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/ride_booking/data/ride_vehicle_classes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body, {this.status = 200});

  final Object body;
  final int status;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<ProviderContainer> _container(_Adapter adapter) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      apiServiceProvider.overrideWith(
        (ref) => ApiService(
          TokenStorage(prefs),
          ref,
          dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
            ..httpClientAdapter = adapter,
        ),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('isDeliveryOnlyVehicle', () {
    const classes = {
      'car': 'standard',
      'bike': 'motorcycle',
      'msg-bike': 'messenger',
      'msg-car': 'motorcycle_delivery',
    };

    bool drop(String id, [String name = '']) => isDeliveryOnlyVehicle(
      vehicleTypeId: id,
      vehicleTypeName: name,
      displayName: name,
      classes: classes,
    );

    test('by vehicle_class when the type list has it', () {
      expect(drop('car'), isFalse);
      expect(drop('bike'), isFalse);
      expect(drop('msg-bike'), isTrue);
      expect(drop('msg-car'), isTrue);
      // The class decides, not a misleading name.
      expect(drop('car', 'Messenger Car'), isFalse);
    });

    test('by name when the type is unknown or the list failed', () {
      expect(drop('unknown', 'Messenger Bike'), isTrue);
      expect(drop('unknown', 'รถส่งของ'), isTrue);
      expect(drop('unknown', 'Comfort'), isFalse);
    });
  });

  test('reads GET /api/vehicle-types?active_only=true', () async {
    final adapter = _Adapter([
      {'id': 'car', 'vehicle_class': 'Standard'},
      {'id': 'msg-bike', 'vehicle_class': 'messenger'},
      {'name': 'no id'},
    ]);
    final c = await _container(adapter);
    final classes = await c.read(rideVehicleClassesProvider.future);
    expect(classes, {'car': 'standard', 'msg-bike': 'messenger'});
    expect(adapter.last!.path, '/api/vehicle-types');
    expect(adapter.last!.queryParameters['active_only'], true);
  });

  test('a failed type list gives none (names are used instead)', () async {
    final c = await _container(_Adapter({'error': 'x'}, status: 500));
    expect(await c.read(rideVehicleClassesProvider.future), isEmpty);
  });
}
