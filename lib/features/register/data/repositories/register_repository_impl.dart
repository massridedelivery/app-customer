import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/features/register/data/datasources/register_remote_data_source.dart';
import 'package:customer_app/features/register/domain/repositories/register_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_repository_impl.g.dart';

@riverpod
RegisterRepository registerRepository(Ref ref) {
  final dataSource = ref.watch(registerRemoteDataSourceProvider);
  return RegisterRepositoryImpl(dataSource);
}

class RegisterRepositoryImpl implements RegisterRepository {
  final RegisterRemoteDataSource _dataSource;

  RegisterRepositoryImpl(this._dataSource);

  @override
  Future<void> register({
    required String email,
    required String fullName,
  }) async {
    try {
      await _dataSource.register(email: email, fullName: fullName);
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? 'Registration failed';
      throw ServerException(message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String deviceType,
  }) async {
    try {
      await _dataSource.registerDevice(token: token, deviceType: deviceType);
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Device registration failed';
      throw ServerException(message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
