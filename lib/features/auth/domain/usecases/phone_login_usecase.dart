import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/utils/either.dart';
import 'package:customer_app/features/auth/data/models/send_otp_response.dart';
import '../entities/phone_login_response.dart';

abstract class PhoneLoginUseCase {
  Future<Either<Failure, SendOtpResponse>> sendOtp({
    required String phone,
    required String role,
  });

  Future<Either<Failure, PhoneLoginResponse>> sendVerifyOtp({
    required String phone,
    required String otp,
    required String role,
    required String refId,
    String? fullName,
  });
}
