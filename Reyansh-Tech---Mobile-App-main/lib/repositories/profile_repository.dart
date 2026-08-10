import '../services/profile_service.dart';
import '../screens/profile/models/user_profile.dart';

export '../screens/profile/models/user_profile.dart';

class ProfileRepository {
  final ProfileService _service;

  ProfileRepository({ProfileService? service})
      : _service = service ?? ProfileService();

  Future<UserProfile> getProfile() => _service.getProfile();

  Future<UserProfile> updateProfile(UserProfile profile) =>
      _service.updateProfile(profile);
}
