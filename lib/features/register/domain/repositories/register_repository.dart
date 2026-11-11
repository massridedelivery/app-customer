abstract interface class RegisterRepository {
  Future<void> register({required String email, required String fullName});
}
