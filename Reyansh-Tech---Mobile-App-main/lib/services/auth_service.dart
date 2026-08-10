import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthService({ApiClient? api, FlutterSecureStorage? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? const FlutterSecureStorage();

  /// Login with email/password using the backend's real auth API.
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    });

    final accessToken = response['access_token'] as String?;
    final refreshToken = response['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw ApiException(
        statusCode: 500,
        message: 'Invalid login response from backend.',
      );
    }

    await _saveTokens(accessToken, refreshToken);
    _api.setToken(accessToken);
    return response;
  }

  /// Kept for compatibility with the existing app flow, but the backend
  /// does not provide phone-based OTP auth.
  Future<void> sendOtp(String phoneNumber) async {
    throw UnsupportedError(
      'This backend uses email/password auth. Use loginWithEmail instead.',
    );
  }

  /// Kept for compatibility with the existing app flow, but the backend
  /// does not provide phone-based OTP auth.
  Future<void> verifyOtp(String phoneNumber, String otp) async {
    throw UnsupportedError(
      'This backend uses email/password auth. Use loginWithEmail instead.',
    );
  }

  /// Restore session from secure storage on app start.
  Future<bool> restoreSession() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return false;
    _api.setToken(token);
    return true;
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    _api.clearToken();
  }

  // ignore: unused_element
  Future<void> _saveTokens(String token, String refreshToken) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }
}
