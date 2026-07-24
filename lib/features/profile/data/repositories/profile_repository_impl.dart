import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:customer_app/features/profile/data/models/profile_model.dart';
import 'package:customer_app/features/profile/domain/entities/profile_entity.dart';
import 'package:customer_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_repository_impl.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) {
  final dataSource = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(dataSource);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProfileEntity> getProfile() async {
    final data = await _remoteDataSource.getProfile();
    final model = ProfileModel.fromJson(data);
    return ProfileEntity(
      userId: model.userId,
      fullName: model.fullName,
      phone: model.phone,
      rating: model.rating,
    );
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    String? emergencyContact,
    Map<String, dynamic>? preferences,
    String? email,
  }) async {
    return _remoteDataSource.updateProfile(
      fullName: fullName,
      emergencyContact: emergencyContact,
      preferences: preferences,
      email: email,
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'เกิดข้อผิดพลาดในการออกจากระบบ';
      throw ServerException(message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
