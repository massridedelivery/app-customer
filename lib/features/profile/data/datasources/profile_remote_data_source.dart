import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_remote_data_source.g.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();
  Future<void> updateProfile({
    required String fullName,
    String? emergencyContact,
    Map<String, dynamic>? preferences,
    String? email,
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
  Future<void> updateProfile({
    required String fullName,
    String? emergencyContact,
    Map<String, dynamic>? preferences,
    String? email,
  }) async {
    await _apiService.dio.put(
      '/api/customer/profile',
      data: {
        'full_name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (emergencyContact != null && emergencyContact.isNotEmpty)
          'emergency_contact': emergencyContact,
        if (preferences != null && preferences.isNotEmpty)
          'preferences': preferences,
      },
    );
  }

  @override
  Future<void> logout() async {
    await _apiService.dio.post('/auth/logout');
  }
}
