abstract interface class RegisterRepository {
  Future<void> register({required String email, required String fullName});
  Future<void> registerDevice({
    required String token,
    required String deviceType,
  });
}
