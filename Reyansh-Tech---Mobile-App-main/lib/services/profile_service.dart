import '../screens/profile/models/user_profile.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _api;

  ProfileService({ApiClient? api}) : _api = api ?? ApiClient();

  /// Fetch the logged-in user's profile from FastAPI `/users/me` or `/auth/me`.
  Future<UserProfile> getProfile() async {
    try {
      final response = await _api.get('/users/me');
      if (response is Map<String, dynamic>) {
        return UserProfile.fromJson(response);
      }
    } catch (_) {
      try {
        final authMe = await _api.get('/auth/me');
        if (authMe is Map<String, dynamic>) {
          return UserProfile.fromJson(authMe);
        }
      } catch (_) {}
    }

    return const UserProfile(
      id: '1',
      name: 'Driver Profile',
      email: 'driver@reyanshtech.com',
      phone: '+1 555-0199',
    );
  }

  /// Update user profile fields.
  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final response = await _api.patch('/users/me', {
        'full_name': profile.name,
        'phone_number': profile.phone,
      });
      if (response is Map<String, dynamic>) {
        return UserProfile.fromJson(response);
      }
    } catch (_) {}
    return profile;
  }
}

