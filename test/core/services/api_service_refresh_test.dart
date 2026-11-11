import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:customer_app/core/configs/app_build.dart';
import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Handler = FutureOr<ResponseBody> Function(RequestOptions o);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  _Handler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

const _pair = {'access_token': 'new-a', 'refresh_token': 'new-r'};

void main() {
  late TokenStorage storage;
  late _Adapter api;
  late _Adapter refresh;
  late ApiService service;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = TokenStorage(prefs);
    await storage.saveTokens(accessToken: 'old-a', refreshToken: 'old-r');

    // The API accepts only the refreshed access token.
    api = _Adapter((o) async {
      final auth = o.headers['Authorization'];
      return auth == 'Bearer new-a'
          ? _json({'ok': true})
          : _json({'error': 'expired'}, 401);
    });
    refresh = _Adapter((_) => _json(_pair));

    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final p = Provider<ApiService>(
      (ref) => ApiService(
        storage,
        ref,
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = api,
        refreshDio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = refresh,
        refreshBackoff: (_) => Duration.zero,
      ),
    );
    service = container.read(p);
  });

  Map<String, dynamic> body(RequestOptions o) =>
      Map<String, dynamic>.from(o.data as Map);

  test('a 401 refreshes once, stores the new pair and replays', () async {
    final res = await service.dio.get('/api/x');
    expect(res.data, {'ok': true});
    expect(refresh.requests, hasLength(1));
    expect(body(refresh.requests.single), {'refresh_token': 'old-r'});
    expect(storage.getAccessToken(), 'new-a');
    expect(storage.getRefreshToken(), 'new-r');
  });

  test('API and refresh requests carry the app build headers', () async {
    AppBuild.debugVersion = '1.0.5+129';
    addTearDown(() => AppBuild.debugVersion = '');
    await service.dio.get('/api/x');
    for (final o in [...api.requests, ...refresh.requests]) {
      expect(o.headers['X-App-Version'], '1.0.5+129');
      expect(o.headers['X-App-Platform'], 'android');
    }
    expect(api.requests, hasLength(2));
    expect(refresh.requests, hasLength(1));
  });

  test('a timeout retries with the SAME refresh token', () async {
    var calls = 0;
    refresh.handler = (o) {
      calls++;
      if (calls == 1) {
        throw DioException(
          requestOptions: o,
          type: DioExceptionType.receiveTimeout,
        );
      }
      return _json(_pair);
    };
    final res = await service.dio.get('/api/x');
    expect(res.data, {'ok': true});
    expect(refresh.requests.map(body).toList(), [
      {'refresh_token': 'old-r'},
      {'refresh_token': 'old-r'},
    ]);
    expect(storage.getRefreshToken(), 'new-r');
  });

  test(
    'a 500 is retried, and when it keeps failing the session stays',
    () async {
      refresh.handler = (_) => _json({'error': 'boom'}, 500);
      await expectLater(
        service.dio.get('/api/x'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(refresh.requests.length, greaterThan(1));
      // Not logged out: the tokens are still there for the next try.
      expect(storage.getAccessToken(), 'old-a');
      expect(storage.getRefreshToken(), 'old-r');
    },
  );

  test('a network error that never recovers keeps the session', () async {
    refresh.handler = (o) => throw DioException(
      requestOptions: o,
      type: DioExceptionType.connectionError,
    );
    await expectLater(service.dio.get('/api/x'), throwsA(isA<DioException>()));
    expect(storage.hasToken, isTrue);
  });

  test('only a 401 from the refresh logs out', () async {
    refresh.handler = (_) => _json({'error': 'invalid refresh token'}, 401);
    await expectLater(service.dio.get('/api/x'), throwsA(isA<DioException>()));
    expect(refresh.requests, hasLength(1));
    expect(storage.hasToken, isFalse);
    expect(storage.getRefreshToken(), isNull);
  });

  test('concurrent 401s share one refresh', () async {
    final gate = Completer<void>();
    refresh.handler = (_) async {
      await gate.future;
      return _json(_pair);
    };
    final all = Future.wait([
      service.dio.get('/api/a'),
      service.dio.get('/api/b'),
      service.dio.get('/api/c'),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    gate.complete();
    final results = await all;
    expect(results.map((r) => r.data), everyElement({'ok': true}));
    expect(refresh.requests, hasLength(1));
  });

  test(
    'a late 401 for a request sent with the old token just replays',
    () async {
      var first = true;
      api.handler = (o) async {
        if (first) {
          first = false;
          // Meanwhile another call refreshed the pair; this answer is for the
          // old token.
          await storage.saveTokens(accessToken: 'new-a', refreshToken: 'new-r');
          return _json({'error': 'expired'}, 401);
        }
        return o.headers['Authorization'] == 'Bearer new-a'
            ? _json({'ok': true})
            : _json({'error': 'expired'}, 401);
      };
      final res = await service.dio.get('/api/late');
      expect(res.data, {'ok': true});
      expect(refresh.requests, isEmpty);
    },
  );
}
