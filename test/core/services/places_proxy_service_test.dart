import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/core/services/places_proxy_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a Dio whose requests are short-circuited: [onGet] returns the Response
/// data (or throws) for a given path, so no real network call is made.
Dio _fakeDio(
  Object? Function(String path, Map<String, dynamic> query) onGet, {
  int status = 200,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final data = onGet(options.path, options.queryParameters);
        handler.resolve(
          Response(requestOptions: options, statusCode: status, data: data),
        );
      },
    ),
  );
  return dio;
}

Dio _errorDio(int status) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: status,
              data: const {'message': 'raw'},
            ),
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  group('PlacesProxyService · autocomplete', () {
    test('parses Google-native predictions + forwards session_token/input', () async {
      String? seenInput;
      String? seenToken;
      final service = PlacesProxyService(_fakeDio((path, query) {
        expect(path, '/api/places/autocomplete');
        seenInput = query['input'] as String?;
        seenToken = query['session_token'] as String?;
        return {
          'predictions': [
            {
              'place_id': 'abc',
              'description': 'Central World, Bangkok',
              'structured_formatting': {
                'main_text': 'Central World',
                'secondary_text': 'Bangkok',
              },
              'distance_meters': 1200,
            },
          ],
          'status': 'OK',
        };
      }));

      final results = await service.autocomplete(
        'central',
        lat: 13.7,
        lng: 100.5,
        sessionToken: 'sess-1',
      );

      expect(seenInput, 'central');
      expect(seenToken, 'sess-1');
      expect(results, hasLength(1));
      expect(results.first.placeId, 'abc');
      expect(results.first.mainText, 'Central World');
      expect(results.first.secondaryText, 'Bangkok');
      expect(results.first.distanceMeters, 1200);
    });

    test('tolerates a normalised {data:[...]} envelope', () async {
      final service = PlacesProxyService(_fakeDio((path, query) {
        return {
          'data': [
            {'place_id': 'x', 'description': 'Somewhere'},
          ],
        };
      }));
      final results = await service.autocomplete('some');
      expect(results.single.placeId, 'x');
      expect(results.single.mainText, 'Somewhere');
    });

    test('503 (key not configured) → Thai "ยังไม่พร้อมใช้งาน"', () async {
      final service = PlacesProxyService(_errorDio(503));
      expect(
        () => service.autocomplete('x', sessionToken: 's'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('ยังไม่พร้อมใช้งาน'),
          ),
        ),
      );
    });

    test('502 (upstream/quota) → Thai "ระบบแผนที่ขัดข้อง"', () async {
      final service = PlacesProxyService(_errorDio(502));
      expect(
        () => service.autocomplete('x'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('ระบบแผนที่ขัดข้อง'),
          ),
        ),
      );
    });
  });

  group('PlacesProxyService · details', () {
    test('parses Google-native result geometry + forwards place_id/token', () async {
      String? seenPlaceId;
      String? seenToken;
      final service = PlacesProxyService(_fakeDio((path, query) {
        expect(path, '/api/places/details');
        seenPlaceId = query['place_id'] as String?;
        seenToken = query['session_token'] as String?;
        return {
          'result': {
            'place_id': 'abc',
            'name': 'Central World',
            'formatted_address': '999 Rama I Rd, Bangkok',
            'geometry': {
              'location': {'lat': 13.7466, 'lng': 100.5393},
            },
          },
          'status': 'OK',
        };
      }));

      final place = await service.placeDetails('abc', sessionToken: 'sess-1');
      expect(seenPlaceId, 'abc');
      expect(seenToken, 'sess-1');
      expect(place.name, 'Central World');
      expect(place.address, '999 Rama I Rd, Bangkok');
      expect(place.lat, 13.7466);
      expect(place.lng, 100.5393);
    });

    test('tolerates a flat {lat,lng,address} shape', () async {
      final service = PlacesProxyService(_fakeDio((path, query) {
        return {
          'place_id': 'abc',
          'name': 'Spot',
          'address': 'Somewhere',
          'lat': 1.0,
          'lng': 2.0,
        };
      }));
      final place = await service.placeDetails('abc');
      expect(place.address, 'Somewhere');
      expect(place.lat, 1.0);
      expect(place.lng, 2.0);
    });

    test('404 → Thai "ไม่พบสถานที่"', () async {
      final service = PlacesProxyService(_errorDio(404));
      expect(
        () => service.placeDetails('missing'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('ไม่พบสถานที่'),
          ),
        ),
      );
    });
  });
}
