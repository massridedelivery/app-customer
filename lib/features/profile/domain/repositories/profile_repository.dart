import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile();

  /// Persists the changes and returns the updated profile echoed back by
  /// `PUT /api/customer/profile`.
  Future<ProfileEntity> updateProfile({
    required String fullName,
    String? emergencyContact,
    Map<String, dynamic>? preferences,
    String? email,
    String? avatarUrl,
  });
  Future<void> logout();
}
