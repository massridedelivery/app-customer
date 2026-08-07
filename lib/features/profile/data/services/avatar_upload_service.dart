import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final avatarUploadServiceProvider = Provider<AvatarUploadService>((ref) {
  return AvatarUploadService(ref.watch(apiServiceProvider));
});

/// Uploads a picked profile image via the Media Service presigned-URL flow and
/// returns the hosted URL to store in the customer's `avatar_url`.
///
/// Three steps (see frontend_integration.md §I "Media Service (Presigned
/// URLs)"):
///   1. `POST /api/media/upload-url` → `{ upload_url, file_key, media_id }`
///   2. `PUT` the raw bytes straight to `upload_url` (direct to storage)
///   3. Return the object's readable URL — the caller persists it via
///      `PUT /api/customer/profile` as `avatar_url`.
///
/// Returns null if any step fails; the caller keeps the local preview and
/// surfaces an "upload failed" message.
class AvatarUploadService {
  AvatarUploadService(this._apiService);

  final ApiService _apiService;

  Future<String?> uploadAvatar(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final fileType = _resolveContentType(image);

      // 1. Ask the API for a presigned upload URL. Goes through the app's Dio
      // so the customer's auth token is attached.
      final res = await _apiService.dio.post(
        '/api/media/upload-url',
        data: {
          'file_type': fileType,
          'file_size': bytes.length,
          'purpose': 'profile_picture',
        },
      );
      final data = res.data as Map<String, dynamic>;
      final uploadUrl = data['upload_url'] as String?;
      if (uploadUrl == null || uploadUrl.isEmpty) return null;

      // 2. PUT the bytes straight to storage. Use a bare Dio so the app's auth
      // interceptor doesn't attach an Authorization header — the presigned URL
      // carries its own signature and storage rejects unexpected auth headers.
      await Dio().put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            Headers.contentTypeHeader: fileType,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      );

      // 3. Resolve the readable URL. Prefer an explicit field if the API sends
      // one; otherwise the stored object lives at the presigned URL minus its
      // signature query string.
      final explicit =
          (data['public_url'] ?? data['media_url'] ?? data['url']) as String?;
      if (explicit != null && explicit.isNotEmpty) return explicit;
      return uploadUrl.split('?').first;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Avatar upload failed: $e');
      }
      return null;
    }
  }

  String _resolveContentType(XFile image) {
    final mime = image.mimeType;
    if (mime != null && mime.isNotEmpty) return mime;
    final path = image.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
