import 'package:customer_app/features/register/domain/repositories/register_repository.dart';
import 'package:customer_app/features/register/data/repositories/register_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_usecase.g.dart';

@riverpod
RegisterUseCase registerUseCase(Ref ref) {
  final repository = ref.watch(registerRepositoryProvider);
  return RegisterUseCase(repository);
}

class RegisterUseCase {
  final RegisterRepository _repository;

  RegisterUseCase(this._repository);

  Future<void> execute({required String email, required String fullName}) {
    return _repository.register(email: email, fullName: fullName);
  }
}
