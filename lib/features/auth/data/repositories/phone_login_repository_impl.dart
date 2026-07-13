import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/utils/either.dart';
import 'package:customer_app/features/auth/data/models/send_otp_response.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/phone_login_response.dart';
import '../../domain/repositories/phone_login_repository.dart';
import '../datasources/phone_login_data_source.dart';
import 'package:dio/dio.dart';

part 'phone_login_repository_impl.g.dart';

@riverpod
PhoneLoginRepositoryImpl phoneLoginRepository(Ref ref) {
  final dataSource = ref.watch(phoneLoginDataSourceProvider);
  return PhoneLoginRepositoryImpl(dataSource);
}

class PhoneLoginRepositoryImpl implements PhoneLoginRepository {
  final PhoneLoginDataSource _dataSource;

  PhoneLoginRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, SendOtpResponse>> sendOtp({
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _dataSource.sendOtp(phone: phone, role: role);
      return Right(SendOtpResponse.fromJson(response));
    } on DioException catch (e) {
      return Left(
        ServerFailure(e.response?.data['message'] ?? 'Failed to send OTP'),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PhoneLoginResponse>> sendVerifyOtp({
    required String phone,
    required String otp,
    required String role,
    required String refId,
    String? fullName,
  }) async {
    try {
      final response = await _dataSource.sendVerifyOtp(
        phone: phone,
        otp: otp,
        role: role,
        refId: refId,
        fullName: fullName,
      );
      return Right(PhoneLoginResponse.fromJson(response));
    } on DioException catch (e) {
      return Left(
        AuthFailure(e.response?.data['message'] ?? 'OTP verification failed'),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
