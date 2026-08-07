import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile();
  Future<void> updateProfile({
    required String fullName,
    String? emergencyContact,
    Map<String, dynamic>? preferences,
    String? email,
  });
  Future<void> logout();
}
