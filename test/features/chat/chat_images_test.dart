import 'dart:async';
import 'dart:typed_data';

import 'package:customer_app/core/data/api_repository.dart';
import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/chat/data/chat_image_processor.dart';
import 'package:customer_app/features/chat/data/chat_media_repository.dart';
import 'package:customer_app/features/chat/domain/chat_room_ids.dart';
import 'package:customer_app/features/chat/domain/models/chat_message.dart';
import 'package:customer_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:customer_app/features/chat/presentation/states/chat_state.dart';
import 'package:customer_app/features/chat/presentation/widgets/chat_image_widgets.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

/// A [w]×[h] JPEG carrying a GPS position and an EXIF [orientation].
Uint8List _phonePhoto(int w, int h, {int orientation = 1}) {
  final image = img.Image(width: w, height: h)
    ..clear(img.ColorRgb8(200, 30, 60));
  image.exif.imageIfd['Orientation'] = orientation;
  image.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(13, 1);
  image.exif.gpsIfd['GPSLongitude'] = img.IfdValueRational(100, 1);
  return img.encodeJpg(image, quality: 95);
}

const _room = (id: 'job-1', kind: ChatKind.ride);
const _fileKey = 'chat/job:job-1/abc.jpg';

class _Socket extends SocketService {
  _Socket(super.tokenStorage);

  final frames = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messages => frames.stream;

  @override
  void connect({bool isReconnect = false}) {}

  @override
  void disconnect() {}
}

class _Api implements ApiRepository {
  final sent = <Map<String, Object?>>[];
  List<dynamic> history = [];
  Object? sendError;

  @override
  Future<List<dynamic>> getJobChat(
    String id, {
    int limit = 50,
    String? before,
  }) async => history;

  @override
  Future<Map<String, dynamic>> sendJobChatMessage(
    String id, {
    required String text,
    required String msgType,
    String? fileKey,
  }) async {
    final error = sendError;
    if (error != null) {
      sendError = null;
      throw error;
    }
    sent.add({'text': text, 'msg_type': msgType, 'file_key': fileKey});
    return {'message': 'sent'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Media implements ChatMediaRepository {
  final uploads = <Uint8List>[];
  final rooms = <String>[];
  Object? error;

  @override
  Future<String> uploadChatImage(
    Uint8List jpeg, {
    required String roomId,
    void Function(double progress)? onProgress,
  }) async {
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
    uploads.add(jpeg);
    rooms.add(roomId);
    onProgress?.call(0.5);
    onProgress?.call(1);
    return _fileKey;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DioException _status(int code) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: code,
  ),
);

void main() {
  group('prepareChatImage', () {
    test('scales to 1600px, re-encodes as JPEG and drops all EXIF (GPS)', () {
      final out = prepareChatImage(_phonePhoto(3200, 2400));
      expect(out.sublist(0, 2), [0xFF, 0xD8]);
      expect(out.length, lessThanOrEqualTo(kChatImageMaxBytes));
      final decoded = img.decodeJpg(out)!;
      expect(decoded.width, 1600);
      expect(decoded.height, 1200);
      expect(decoded.exif.isEmpty, isTrue);
      expect(decoded.exif.gpsIfd.isEmpty, isTrue);
    });

    test('applies the EXIF rotation to the pixels before dropping it', () {
      // Orientation 6 = rotate 90°: a landscape sensor image shown portrait.
      final decoded = img.decodeJpg(
        prepareChatImage(_phonePhoto(400, 300, orientation: 6)),
      )!;
      expect(decoded.width, 300);
      expect(decoded.height, 400);
    });

    test('a small photo keeps its size', () {
      final decoded = img.decodeJpg(prepareChatImage(_phonePhoto(800, 600)))!;
      expect((decoded.width, decoded.height), (800, 600));
    });

    test('a transparent PNG becomes a JPEG', () {
      final png = img.encodePng(
        img.Image(width: 10, height: 10, numChannels: 4),
      );
      expect(prepareChatImage(png).sublist(0, 2), [0xFF, 0xD8]);
    });

    test('not an image → FormatException', () {
      expect(
        () => prepareChatImage(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
    });
  });

  group('room ids', () {
    test('strip the vertical prefix', () {
      expect(bareChatRoomId('job:abc'), 'abc');
      expect(bareChatRoomId('order:abc'), 'abc');
      expect(bareChatRoomId('messenger:abc'), 'abc');
      expect(bareChatRoomId('abc'), 'abc');
    });

    test('route each vertical to its chat screen', () {
      expect(chatRouteForRoom('job:abc'), '/chat/abc');
      expect(chatRouteForRoom('order:abc'), '/food-order/chat/abc');
      expect(chatRouteForRoom('messenger:abc'), '/messenger/chat/abc');
      expect(chatRouteForRoom('abc'), '/chat/abc');
    });

    test('file key from a presigned media_url', () {
      expect(
        chatFileKeyFromUrl(
          'https://s3.example.com/mass/chat/job:job-1/abc.jpg?X-Amz-Expires=300',
        ),
        _fileKey,
      );
      expect(chatFileKeyFromUrl('https://x.com/avatar/a.jpg'), isNull);
      expect(chatFileKeyFromUrl(null), isNull);
    });
  });

  test('ChatMessage reads a WebSocket chat frame', () {
    final m = ChatMessage.fromJson({
      'id': 'm1',
      'job_id': 'job-1',
      'sender_id': 'd1',
      'sender_type': 'driver',
      'content': '',
      'msg_type': 'image',
      'media_url': 'https://s3/mass/chat/job:job-1/x.jpg?sig',
      'created_at': '2026-10-28T10:00:00Z',
    });
    expect(m.isImage, isTrue);
    expect(m.senderRole, 'driver');
    expect(m.text, '');
    expect(m.sentAt, DateTime.utc(2026, 10, 28, 10));
    final text = ChatMessage.fromJson({
      'id': 'm2',
      'sender_type': 'customer',
      'content': 'hi',
      'msg_type': 'text',
      'media_url': '',
      'created_at': '2026-10-28T10:00:00Z',
    });
    expect(text.text, 'hi');
    expect(text.mediaUrl, isNull);
  });

  group('controller', () {
    late _Api api;
    late _Media media;
    late _Socket socket;
    late ProviderContainer c;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      api = _Api();
      media = _Media();
      socket = _Socket(TokenStorage(prefs));
      c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiRepositoryProvider.overrideWithValue(api),
          chatMediaRepositoryProvider.overrideWithValue(media),
          socketServiceProvider.overrideWithValue(socket),
        ],
      );
      addTearDown(c.dispose);
      c.listen(chatControllerProvider(_room), (_, _) {});
      await Future<void>.delayed(Duration.zero);
    });

    ChatState st() => c.read(chatControllerProvider(_room));
    ChatController n() => c.read(chatControllerProvider(_room).notifier);

    void frame(Map<String, dynamic> data, {String room = 'job:job-1'}) => socket
        .frames
        .add({'type': 'chat_message', 'room_id': room, 'data': data});

    test('sends: processed upload, image message, echo replaces it', () async {
      await n().sendImage(_phonePhoto(3200, 2400), caption: ' ดูตรงนี้ ');

      expect(media.rooms, ['job-1']);
      final uploaded = img.decodeJpg(media.uploads.single)!;
      expect(uploaded.width, 1600);
      expect(uploaded.exif.gpsIfd.isEmpty, isTrue);
      expect(api.sent.single, {
        'text': 'ดูตรงนี้',
        'msg_type': 'image',
        'file_key': _fileKey,
      });
      final temp = st().messages.single;
      expect(temp.id, startsWith('opt-'));
      expect(st().imageUploads[temp.id]!.status, ChatImageUploadStatus.sent);

      // The echo (no file_key, just the presigned URL) takes its place.
      frame({
        'id': 'srv-1',
        'sender_id': 'c1',
        'sender_type': 'customer',
        'content': 'ดูตรงนี้',
        'msg_type': 'image',
        'media_url': 'https://s3/mass/$_fileKey?sig=1',
        'created_at': '2026-10-28T10:00:00Z',
      });
      await Future<void>.delayed(Duration.zero);
      expect(st().messages.map((m) => m.id), ['srv-1']);
      // Still shown from memory under the server id.
      expect(st().imageUploads.keys, ['srv-1']);

      // A second delivery of the same frame is dropped (data.id).
      frame({
        'id': 'srv-1',
        'sender_type': 'customer',
        'content': 'ดูตรงนี้',
        'msg_type': 'image',
        'media_url': 'https://s3/mass/$_fileKey?sig=2',
        'created_at': '2026-10-28T10:00:00Z',
      });
      await Future<void>.delayed(Duration.zero);
      expect(st().messages, hasLength(1));
    });

    test('403 on send → blocked; retry only re-sends the message', () async {
      api.sendError = _status(403);
      await n().sendImage(_phonePhoto(200, 200));
      final id = st().messages.single.id;
      expect(st().imageUploads[id]!.status, ChatImageUploadStatus.failed);
      expect(st().imageUploads[id]!.error, ChatImageError.blocked);

      await n().retryImage(id);
      expect(media.uploads, hasLength(1), reason: 'upload not repeated');
      expect(api.sent.single['file_key'], _fileKey);
      expect(st().imageUploads[id]!.status, ChatImageUploadStatus.sent);
    });

    test(
      'a failed upload is invalid; retry uploads again; discard drops it',
      () async {
        media.error = const ChatImageException(ChatImageError.invalid);
        await n().sendImage(_phonePhoto(200, 200));
        final id = st().messages.single.id;
        expect(st().imageUploads[id]!.error, ChatImageError.invalid);
        expect(api.sent, isEmpty);

        await n().retryImage(id);
        expect(media.uploads, hasLength(1));
        expect(api.sent, hasLength(1));

        media.error = const ChatImageException(ChatImageError.failed);
        await n().sendImage(_phonePhoto(200, 200));
        final failed = st().messages.last.id;
        n().discardImage(failed);
        expect(st().messages.map((m) => m.id), isNot(contains(failed)));
        expect(st().imageUploads.containsKey(failed), isFalse);
      },
    );

    test('a non-image file fails as invalid without uploading', () async {
      await n().sendImage(Uint8List.fromList([1, 2, 3]));
      final id = st().messages.single.id;
      expect(st().imageUploads[id]!.error, ChatImageError.invalid);
      expect(media.uploads, isEmpty);
    });

    test('driver frames: prefixed room matched, other rooms ignored', () async {
      frame({
        'id': 'd-1',
        'sender_id': 'd1',
        'sender_type': 'driver',
        'content': '',
        'msg_type': 'image',
        'media_url': 'https://s3/mass/chat/job:job-1/d.jpg?sig',
        'created_at': '2026-10-28T10:00:00Z',
      });
      frame({
        'id': 'other',
        'sender_type': 'driver',
        'content': 'x',
        'msg_type': 'text',
        'created_at': '2026-10-28T10:00:00Z',
      }, room: 'job:job-2');
      await Future<void>.delayed(Duration.zero);
      expect(st().messages.map((m) => m.id), ['d-1']);
      expect(st().messages.single.isImage, isTrue);
    });

    test('a history reload keeps photos still being sent', () async {
      media.error = const ChatImageException(ChatImageError.failed);
      await n().sendImage(_phonePhoto(200, 200));
      api.history = [
        {
          'id': 'h1',
          'sender_id': 'd1',
          'sender_role': 'driver',
          'msg_type': 'text',
          'text': 'hello',
          'sent_at': '2026-10-28T09:00:00Z',
        },
      ];
      await n().fetchChatHistory();
      expect(st().messages.first.id, 'h1');
      expect(st().messages.last.id, startsWith('opt-'));
    });
  });

  group('bubble', () {
    Future<void> pump(WidgetTester tester, ChatImageUpload upload) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('th'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProviderScope(
              child: ChatImageBubble(
                message: ChatMessage(
                  id: 'opt-1',
                  senderId: 'me',
                  senderRole: 'customer',
                  msgType: 'image',
                  text: 'คำบรรยาย',
                  sentAt: DateTime(2026),
                ),
                isMe: true,
                upload: upload,
                onRetry: () {},
                onDiscard: () {},
              ),
            ),
          ),
        ),
      );
    }

    final bytes = img.encodePng(img.Image(width: 4, height: 4));

    testWidgets('sending: progress ring and caption', (tester) async {
      await pump(tester, ChatImageUpload(bytes: bytes, progress: 0.4));
      expect(find.byKey(const Key('chatImageProgress')), findsOneWidget);
      expect(find.text('คำบรรยาย'), findsOneWidget);
      expect(find.byKey(const Key('chatImageRetry')), findsNothing);
    });

    testWidgets('failed: Thai error, retry and delete', (tester) async {
      await pump(
        tester,
        ChatImageUpload(
          bytes: bytes,
          status: ChatImageUploadStatus.failed,
          error: ChatImageError.invalid,
        ),
      );
      expect(find.byKey(const Key('chatImageRetry')), findsOneWidget);
      expect(find.byKey(const Key('chatImageDiscard')), findsOneWidget);
      expect(
        find.text(
          'ไฟล์ไม่ถูกต้อง ใหญ่เกินไป หรืออัปโหลดไม่สำเร็จ กรุณาอัปโหลดใหม่',
        ),
        findsOneWidget,
      );
    });

    testWidgets('blocked: no retry, says why', (tester) async {
      await pump(
        tester,
        ChatImageUpload(
          bytes: bytes,
          status: ChatImageUploadStatus.failed,
          error: ChatImageError.blocked,
        ),
      );
      expect(find.byKey(const Key('chatImageRetry')), findsNothing);
      expect(find.text('คุณถูกบล็อก จึงส่งรูปในแชทนี้ไม่ได้'), findsOneWidget);
    });

    testWidgets('tap opens the zoomable full-screen viewer', (tester) async {
      await pump(
        tester,
        ChatImageUpload(bytes: bytes, status: ChatImageUploadStatus.sent),
      );
      await tester.tap(find.byType(Image).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chatImageViewer')), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });
}
