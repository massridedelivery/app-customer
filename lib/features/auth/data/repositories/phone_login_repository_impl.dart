import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/utils/either.dart';
import 'package:customer_app/features/auth/data/models/send_otp_response.dart';
import 'package:customer_app/features/auth/data/otp_send_errors.dart';
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
      return Left(otpSendFailureOf(e));
    } catch (_) {
      // A 200 without a ref_id, or a body that isn't the expected JSON.
      return const Left(OtpSendFailure(OtpSendError.server));
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
      // The body can be a proxy's HTML page: read it only when it's JSON.
      final data = e.response?.data;
      final text = data is Map ? data['error'] ?? data['message'] : null;
      return Left(AuthFailure(text is String ? text : ''));
    } catch (_) {
      return const Left(ServerFailure(''));
    }
  }
}
