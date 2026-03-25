import '../models/profile_details.dart';
import 'profile_api_service.dart';

class ProfileRepository {
  ProfileRepository({ProfileApiService? apiService})
    : _apiService = apiService ?? ProfileApiService();

  final ProfileApiService _apiService;

  Future<ProfileDetails> getMyProfile() {
    return _apiService.fetchMyProfile();
  }

  Future<ProfileDetails> saveMyProfile(ProfileDetails profile) {
    return _apiService.updateMyProfile(profile);
  }
}
