import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _service;

  AuthRepository({AuthService? service})
      : _service = service ?? AuthService();

  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) =>
      _service.loginWithEmail(email: email, password: password);

  Future<void> sendOtp(String phoneNumber) => _service.sendOtp(phoneNumber);

  Future<void> verifyOtp(String phoneNumber, String otp) =>
      _service.verifyOtp(phoneNumber, otp);

  Future<bool> restoreSession() => _service.restoreSession();

  Future<void> logout() => _service.logout();
}
