import 'dart:convert';
import 'dart:typed_data';

import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/chat/data/chat_media_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each request from [handler] and records it.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final ResponseBody Function(RequestOptions o, List<int> body) handler;
  final requests = <(RequestOptions, List<int>)>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        body.addAll(chunk);
      }
    }
    requests.add((options, body));
    return handler(options, body);
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

class _Api implements ApiService {
  _Api(this.dio);

  @override
  final Dio dio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final jpeg = Uint8List.fromList(List.filled(1000, 7));

  ({ChatMediaRepository repo, _Adapter api, _Adapter storage}) setUpRepo({
    int urlStatus = 200,
    int putStatus = 200,
    int maxBytes = 2097152,
  }) {
    final api = _Adapter((o, _) {
      if (o.path == '/api/media/upload-url') {
        return urlStatus == 200
            ? _json({
                'upload_url': 'https://s3.test/put?sig=1',
                'file_key': 'chat/job:job-1/x.jpg',
                'max_bytes': maxBytes,
              })
            : _json({'error': 'nope'}, urlStatus);
      }
      return _json({'ok': true});
    });
    final storage = _Adapter((o, _) => ResponseBody.fromString('', putStatus));
    final apiDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = api;
    final storageDio = Dio()..httpClientAdapter = storage;
    return (
      repo: ChatMediaRepository(_Api(apiDio), storageDio: storageDio),
      api: api,
      storage: storage,
    );
  }

  test('upload-url (chat, jpeg, bare room id) → PUT raw → confirm', () async {
    final s = setUpRepo();
    final progress = <double>[];
    final key = await s.repo.uploadChatImage(
      jpeg,
      roomId: 'job-1',
      onProgress: progress.add,
    );
    expect(key, 'chat/job:job-1/x.jpg');

    final (get, _) = s.api.requests[0];
    expect(get.method, 'GET');
    expect(get.queryParameters, {
      'category': 'chat',
      'content_type': 'image/jpeg',
      'room_id': 'job-1',
    });

    final (put, body) = s.storage.requests.single;
    expect(put.method, 'PUT');
    expect(put.uri.toString(), 'https://s3.test/put?sig=1');
    expect(put.headers[Headers.contentTypeHeader], 'image/jpeg');
    expect(put.headers['Authorization'], isNull);
    expect(body, jpeg);
    expect(progress, isNotEmpty);

    final (confirm, confirmBody) = s.api.requests[1];
    expect(confirm.path, '/api/media/confirm');
    expect(jsonDecode(utf8.decode(confirmBody)), {
      'file_key': 'chat/job:job-1/x.jpg',
    });
  });

  test('403 → blocked, 400 / 422 → invalid, 500 → failed', () async {
    for (final (status, error) in [
      (403, ChatImageError.blocked),
      (400, ChatImageError.invalid),
      (422, ChatImageError.invalid),
      (500, ChatImageError.failed),
    ]) {
      final s = setUpRepo(urlStatus: status);
      await expectLater(
        s.repo.uploadChatImage(jpeg, roomId: 'job-1'),
        throwsA(
          isA<ChatImageException>().having((e) => e.error, 'error', error),
        ),
      );
    }
  });

  test('storage refusing the PUT → invalid, upload again', () async {
    final s = setUpRepo(putStatus: 403);
    await expectLater(
      s.repo.uploadChatImage(jpeg, roomId: 'job-1'),
      throwsA(
        isA<ChatImageException>().having(
          (e) => e.error,
          'error',
          ChatImageError.invalid,
        ),
      ),
    );
    expect(s.api.requests, hasLength(1), reason: 'never confirmed');
  });

  test('over max_bytes → invalid before uploading', () async {
    final s = setUpRepo(maxBytes: 10);
    await expectLater(
      s.repo.uploadChatImage(jpeg, roomId: 'job-1'),
      throwsA(isA<ChatImageException>()),
    );
    expect(s.storage.requests, isEmpty);
  });
}
