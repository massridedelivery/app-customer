import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:customer_app/features/profile/data/models/profile_model.dart';
import 'package:customer_app/features/profile/domain/entities/profile_entity.dart';
import 'package:customer_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
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
    return _toEntity(ProfileModel.fromJson(data));
  }

  @override
  Future<ProfileEntity> updateProfile({
    required String fullName,
    String? emergencyContact,
    Map<String, dynamic>? preferences,
    String? email,
    String? avatarUrl,
  }) async {
    final data = await _remoteDataSource.updateProfile(
      fullName: fullName,
      emergencyContact: emergencyContact,
      preferences: preferences,
      email: email,
      avatarUrl: avatarUrl,
    );
    return _toEntity(ProfileModel.fromJson(data));
  }

  ProfileEntity _toEntity(ProfileModel model) => ProfileEntity(
    userId: model.userId,
    fullName: model.fullName,
    phone: model.phone,
    rating: model.rating,
    avatarUrl: model.avatarUrl,
    email: model.email,
    emergencyContact: model.emergencyContact,
    preferences: model.preferences,
    totalTrips: model.totalTrips,
    createdAt: model.createdAt,
    joinedDateThai: model.joinedDateThai,
    savedPlaces: model.savedPlaces ?? const <Place>[],
  );

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
