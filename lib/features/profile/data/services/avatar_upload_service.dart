import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final avatarUploadServiceProvider = Provider<AvatarUploadService>((ref) {
  return AvatarUploadService(ref.watch(apiServiceProvider));
});

/// Uploads a picked profile image via the MinIO-native media protocol and
/// returns the `file_key` to persist on the customer's profile.
///
/// Follows the 3-step protocol from SCRUM-16 (Media System Architecture),
/// category `avatar` (Public, ≤2MB, jpeg/png/webp):
///   1. `GET /api/media/upload-url?category=avatar&content_type=<mime>`
///      → `{ upload_url, file_key, max_bytes, expires_at }`
///   2. `PUT` the raw binary straight to `upload_url` — Content-Type must match
///      step 1 exactly, and it must be a raw blob (a FormData wrapper breaks the
///      MinIO signature).
///   3. `POST /api/media/confirm { file_key }` to finalize the object.
///
/// Returns the `file_key`, which is what `PUT /api/customer/profile` expects for
/// `avatar_url`: the backend owns URL resolution and echoes back a readable
/// avatar URL, so the client never reconstructs one from the presigned link.
/// Returns null if any step fails; the caller keeps the local preview and
/// surfaces an "upload failed" message.
class AvatarUploadService {
  AvatarUploadService(this._apiService);

  final ApiService _apiService;

  Future<String?> uploadAvatar(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final contentType = _avatarContentType(image);

      // 1. Request a presigned upload URL. Goes through the app's Dio so the
      // customer's auth token is attached.
      final res = await _apiService.dio.get(
        '/api/media/upload-url',
        queryParameters: {'category': 'avatar', 'content_type': contentType},
      );
      final data = res.data as Map<String, dynamic>;
      final uploadUrl = data['upload_url'] as String?;
      final fileKey = data['file_key'] as String?;
      if (uploadUrl == null || uploadUrl.isEmpty || fileKey == null) {
        return null;
      }

      // Enforce the category's size cap client-side so we fail fast instead of
      // letting storage reject an oversized blob mid-upload.
      final maxBytes = (data['max_bytes'] as num?)?.toInt();
      if (maxBytes != null && bytes.length > maxBytes) {
        if (kDebugMode) {
          debugPrint('Avatar too large: ${bytes.length} > $maxBytes bytes');
        }
        return null;
      }

      // 2. PUT the raw bytes straight to storage. Use a bare Dio so the app's
      // auth interceptor doesn't attach an Authorization header — the presigned
      // URL carries its own signature and MinIO rejects unexpected auth headers.
      // Content-Type must match step 1 exactly; the body is a raw blob (no
      // FormData, which would corrupt the signature).
      await Dio().put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      );

      // 3. Confirm the upload so the backend finalizes the object.
      await _apiService.dio.post(
        '/api/media/confirm',
        data: {'file_key': fileKey},
      );

      // Hand the file_key back to the profile update; the backend resolves it
      // to a readable avatar URL.
      return fileKey;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Avatar upload failed: $e');
      }
      return null;
    }
  }

  /// Resolves the Content-Type, restricted to what the `avatar` category allows
  /// (jpeg/png/webp). image_picker re-encodes to JPEG when `imageQuality` is
  /// set, so anything else (e.g. HEIC) is treated as JPEG.
  String _avatarContentType(XFile image) {
    final mime = image.mimeType?.toLowerCase();
    const allowed = {'image/jpeg', 'image/png', 'image/webp'};
    if (mime != null && allowed.contains(mime)) return mime;
    final path = image.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
