import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_remote_data_source.g.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();

  /// Returns the updated profile body. `PUT /api/customer/profile` echoes back
  /// the full profile, so callers can use it directly without a follow-up GET.
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? emergencyContact,
    Map<String, dynamic>? preferences,
    String? email,
    String? avatarUrl,
  });
  Future<void> logout();
}

@riverpod
ProfileRemoteDataSourceImpl profileRemoteDataSource(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProfileRemoteDataSourceImpl(apiService);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiService _apiService;

  ProfileRemoteDataSourceImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiService.dio.get('/api/customer/profile');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? emergencyContact,
    Map<String, dynamic>? preferences,
    String? email,
    String? avatarUrl,
  }) async {
    // Partial update: only send fields the caller actually provided so blank
    // values don't overwrite existing server data.
    final response = await _apiService.dio.put(
      '/api/customer/profile',
      data: {
        'full_name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (emergencyContact != null && emergencyContact.isNotEmpty)
          'emergency_contact': emergencyContact,
        if (preferences != null && preferences.isNotEmpty)
          'preferences': preferences,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> logout() async {
    await _apiService.dio.post('/auth/logout');
  }
}
