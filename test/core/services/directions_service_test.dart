import 'package:customer_app/core/services/directions_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// "_p~iF~ps|U_ulLnnqC_mqNvxq`@" → (38.5,-120.2) (40.7,-120.95) (43.252,-126.453)
const _encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

Dio _dio(void Function(RequestOptions o, RequestInterceptorHandler h) onReq) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: onReq));
  return dio;
}

void main() {
  const origin = LatLng(18.7883, 98.9853);
  const destination = LatLng(18.8, 99.0);

  test('calls /api/directions with lat,lng origin/destination and no key',
      () async {
    late RequestOptions seen;
    final service = DirectionsService(_dio((o, h) {
      seen = o;
      h.resolve(Response(
        requestOptions: o,
        statusCode: 200,
        data: const {'polyline': _encoded},
      ));
    }));
    final points = await service.route(origin, destination);
    expect(seen.path, '/api/directions');
    expect(seen.queryParameters['origin'], '18.7883,98.9853');
    expect(seen.queryParameters['destination'], '18.8,99.0');
    expect(seen.queryParameters.containsKey('key'), isFalse);
    expect(points, hasLength(3));
    expect(points.first.latitude, closeTo(38.5, 1e-5));
  });

  test('reads Google-shaped routes[0].overview_polyline.points', () {
    expect(
      DirectionsService.encodedPolylineOf({
        'routes': [
          {
            'overview_polyline': {'points': _encoded},
          },
        ],
      }),
      _encoded,
    );
  });

  test('an estimated (straight-line) route is still drawn', () async {
    final service = DirectionsService(_dio((o, h) {
      h.resolve(Response(
        requestOptions: o,
        statusCode: 200,
        data: const {'polyline': _encoded, 'estimated': true},
      ));
    }));
    expect(await service.route(origin, destination), hasLength(3));
  });

  for (final status in [400, 502]) {
    test('$status → empty route (map keeps the straight line)', () async {
      final service = DirectionsService(_dio((o, h) {
        h.reject(DioException(
          requestOptions: o,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: o, statusCode: status),
        ));
      }));
      expect(await service.route(origin, destination), isEmpty);
    });
  }
}
