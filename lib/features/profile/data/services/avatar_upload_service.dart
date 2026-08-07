import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final avatarUploadServiceProvider = Provider<AvatarUploadService>((ref) {
  return AvatarUploadService();
});

/// Uploads a picked image and returns the hosted URL to store in the customer's
/// `avatar_url`.
///
/// NOT WIRED YET — the customer API has no file-upload endpoint (only driver
/// KYC uploads exist: `POST /api/driver/onboarding/document|liveness`). Once the
/// backend adds a customer upload endpoint (e.g. `POST /api/customer/upload`
/// returning `{ "url": "https://..." }`), implement [uploadAvatar] to POST the
/// file there and return the URL. Until then it returns null: the picked image
/// still previews locally and the rest of the profile save proceeds, but no
/// remote `avatar_url` is set.
class AvatarUploadService {
  Future<String?> uploadAvatar(XFile image) async {
    // TODO(avatar-upload): POST `image` as multipart/form-data to the customer
    // upload endpoint once it exists, then return the resulting URL. This is the
    // ONLY place that needs changing to finish avatar upload.
    return null;
  }
}
