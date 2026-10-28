import 'dart:typed_data';

import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatMediaRepositoryProvider = Provider<ChatMediaRepository>((ref) {
  return ChatMediaRepository(ref.watch(apiServiceProvider));
});

/// Why sending a chat photo failed, for the Thai message under the bubble.
enum ChatImageError {
  /// 403: the rider blocked the customer (or they're not in this chat).
  blocked,

  /// 400 / 413 / 422, or a file that couldn't be read: upload it again.
  invalid,

  /// Network or server trouble: try again.
  failed,
}

class ChatImageException implements Exception {
  const ChatImageException(this.error, [this.cause]);

  final ChatImageError error;
  final Object? cause;

  /// Maps a failed request to what the customer is told.
  factory ChatImageException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    return ChatImageException(switch (status) {
      403 => ChatImageError.blocked,
      400 || 413 || 422 => ChatImageError.invalid,
      _ => ChatImageError.failed,
    }, e);
  }

  @override
  String toString() => 'ChatImageException($error, $cause)';
}

/// Uploads chat photos with the media protocol (SCRUM-16), category `chat`:
///   1. `GET /api/media/upload-url?category=chat&content_type=image/jpeg&room_id=<id>`
///      → `{upload_url, file_key, max_bytes}` (the link lasts 15 minutes)
///   2. `PUT` the raw JPEG to `upload_url` with the same Content-Type
///   3. `POST /api/media/confirm {file_key}`
/// The returned `file_key` is then sent as an `image` chat message.
class ChatMediaRepository {
  ChatMediaRepository(this._apiService, {Dio? storageDio})
    : _storageDio = storageDio ?? Dio();

  final ApiService _apiService;

  // Bare client for the presigned PUT: the app's auth header would break the
  // storage signature.
  final Dio _storageDio;

  static const _contentType = 'image/jpeg';

  /// Uploads [jpeg] for the chat of [roomId] (the bare job / order id) and
  /// returns its `file_key`. [onProgress] gets 0..1 while the bytes go up.
  /// Throws [ChatImageException].
  Future<String> uploadChatImage(
    Uint8List jpeg, {
    required String roomId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final res = await _apiService.dio.get(
        '/api/media/upload-url',
        queryParameters: {
          'category': 'chat',
          'content_type': _contentType,
          'room_id': roomId,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final uploadUrl = data['upload_url'] as String?;
      final fileKey = data['file_key'] as String?;
      if (uploadUrl == null || uploadUrl.isEmpty || fileKey == null) {
        throw const ChatImageException(ChatImageError.failed);
      }
      final maxBytes = (data['max_bytes'] as num?)?.toInt();
      if (maxBytes != null && jpeg.length > maxBytes) {
        throw const ChatImageException(ChatImageError.invalid);
      }

      try {
        await _storageDio.put(
          uploadUrl,
          data: Stream.fromIterable([jpeg]),
          options: Options(
            headers: {
              Headers.contentTypeHeader: _contentType,
              Headers.contentLengthHeader: jpeg.length,
            },
          ),
          onSendProgress: (sent, total) {
            if (total > 0) onProgress?.call(sent / total);
          },
        );
      } on DioException catch (e) {
        // Storage refused the bytes (expired link, size, type): upload again.
        // No response at all is the network: just try again.
        throw ChatImageException(
          e.response == null ? ChatImageError.failed : ChatImageError.invalid,
          e,
        );
      }

      await _apiService.dio.post(
        '/api/media/confirm',
        data: {'file_key': fileKey},
      );
      return fileKey;
    } on DioException catch (e) {
      throw ChatImageException.fromDio(e);
    }
  }
}
