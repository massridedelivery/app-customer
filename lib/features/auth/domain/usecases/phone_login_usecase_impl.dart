import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/utils/either.dart';
import 'package:customer_app/features/auth/data/models/send_otp_response.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/phone_login_repository_impl.dart';
import '../entities/phone_login_response.dart';
import '../repositories/phone_login_repository.dart';
import 'phone_login_usecase.dart';

part 'phone_login_usecase_impl.g.dart';

@riverpod
PhoneLoginUseCaseImpl phoneLoginUseCase(Ref ref) {
  final repository = ref.watch(phoneLoginRepositoryProvider);
  return PhoneLoginUseCaseImpl(repository);
}

class PhoneLoginUseCaseImpl implements PhoneLoginUseCase {
  final PhoneLoginRepository _repository;

  PhoneLoginUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, SendOtpResponse>> sendOtp({
    required String phone,
    required String role,
  }) {
    return _repository.sendOtp(phone: phone, role: role);
  }

  @override
  Future<Either<Failure, PhoneLoginResponse>> sendVerifyOtp({
    required String phone,
    required String otp,
    required String role,
    required String refId,
    String? fullName,
  }) {
    return _repository.sendVerifyOtp(
      phone: phone,
      otp: otp,
      role: role,
      refId: refId,
      fullName: fullName,
    );
  }
}
