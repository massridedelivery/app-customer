import 'dart:convert';
import 'dart:typed_data';

import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/utils/countdown.dart';
import 'package:customer_app/features/auth/data/datasources/phone_login_data_source.dart';
import 'package:customer_app/features/auth/data/otp_send_errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.answer);

  final ResponseBody Function() answer;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return answer();
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, int status, [Map<String, String>? extra]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final e in (extra ?? {}).entries) e.key: [e.value],
      },
    );

DioException _error(int status, Object? body, {Map<String, String>? headers}) {
  final options = RequestOptions(path: '/auth/otp/send');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: body,
      headers: Headers.fromMap({
        for (final e in (headers ?? {}).entries) e.key: [e.value],
      }),
    ),
  );
}

void main() {
  group('otpSendFailureOf', () {
    test('400 INVALID_PHONE keeps the server text', () {
      final f = otpSendFailureOf(
        _error(400, {
          'error': 'เบอร์โทรไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง',
          'code': 'INVALID_PHONE',
        }),
      );
      expect(f.kind, OtpSendError.invalidPhone);
      expect(f.message, 'เบอร์โทรไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง');
      expect(f.code, 'INVALID_PHONE');
    });

    test('400 without a code is still a bad number', () {
      final f = otpSendFailureOf(_error(400, {'error': 'invalid phone'}));
      expect(f.kind, OtpSendError.invalidPhone);
    });

    test('403 suspended / deleted', () {
      for (final code in ['account_suspended', 'account_deleted']) {
        final f = otpSendFailureOf(_error(403, {'code': code}));
        expect(f.kind, OtpSendError.accountBlocked);
        expect(f.code, code);
      }
      // Any other 403 must still show something.
      expect(
        otpSendFailureOf(_error(403, {'error': 'forbidden'})).kind,
        OtpSendError.server,
      );
    });

    test('429 reads retry_after, then the Retry-After header', () {
      final body = otpSendFailureOf(
        _error(429, {
          'error': 'ขอ OTP บ่อยเกินไป',
          'code': 'OTP_RATE_LIMITED',
          'retry_after': 754,
        }),
      );
      expect(body.kind, OtpSendError.rateLimited);
      expect(body.retryAfter, 754);
      expect(body.message, 'ขอ OTP บ่อยเกินไป');

      final header = otpSendFailureOf(
        _error(
          429,
          {'code': 'OTP_RATE_LIMITED'},
          headers: {'retry-after': '120'},
        ),
      );
      expect(header.retryAfter, 120);
      expect(header.message, isEmpty); // the UI's own wording

      expect(otpSendFailureOf(_error(429, null)).retryAfter, 60);
    });

    test("500 is a provider failure; its English text isn't shown", () {
      final f = otpSendFailureOf(_error(500, {'error': 'failed to send OTP'}));
      expect(f.kind, OtpSendError.sendFailed);
      expect(f.message, isEmpty);
    });

    test('an HTML 404 / 502 body is a server error, not a crash', () {
      for (final status in [404, 502]) {
        final f = otpSendFailureOf(_error(status, '<html>Bad Gateway</html>'));
        expect(f.kind, OtpSendError.server);
        expect(f.status, status);
      }
    });

    test('no response is a network error', () {
      final f = otpSendFailureOf(
        DioException(
          requestOptions: RequestOptions(path: '/auth/otp/send'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(f.kind, OtpSendError.network);
    });
  });

  group('PhoneLoginDataSourceImpl.sendOtp', () {
    Dio dio(_Adapter adapter) =>
        Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter;

    test('posts phone, role and the install id to /auth/otp/send', () async {
      final adapter = _Adapter(
        () => _json({
          'message': 'ok',
          'ref_id': 'ref-1',
          'is_registered': true,
        }, 200),
      );
      final res = await PhoneLoginDataSourceImpl(
        dio(adapter),
        'install-42',
      ).sendOtp(phone: '+66892616445', role: 'customer');

      expect(res['ref_id'], 'ref-1');
      expect(adapter.requests.single.path, '/auth/otp/send');
      expect(adapter.requests.single.data, {
        'phone': '+66892616445',
        'role': 'customer',
        'device_id': 'install-42',
      });
    });

    test('a 200 without a ref_id is not a success', () async {
      final adapter = _Adapter(() => _json({'message': 'ok'}, 200));
      expect(
        PhoneLoginDataSourceImpl(
          dio(adapter),
          'd',
        ).sendOtp(phone: '+66892616445', role: 'customer'),
        throwsFormatException,
      );
    });

    test('a 429 comes back as a DioException', () async {
      final adapter = _Adapter(
        () => _json(
          {'code': 'OTP_RATE_LIMITED', 'retry_after': 30},
          429,
          {'retry-after': '30'},
        ),
      );
      await expectLater(
        PhoneLoginDataSourceImpl(
          dio(adapter),
          'd',
        ).sendOtp(phone: '+66892616445', role: 'customer'),
        throwsA(
          isA<DioException>().having(
            (e) => otpSendFailureOf(e).retryAfter,
            'retryAfter',
            30,
          ),
        ),
      );
      expect(adapter.requests, hasLength(1));
    });
  });

  test('formatCountdown', () {
    expect(formatCountdown(42), '00:42');
    expect(formatCountdown(754), '12:34');
    expect(formatCountdown(5400), '1:30:00');
    expect(formatCountdown(-3), '00:00');
  });
}
