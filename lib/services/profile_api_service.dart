import '../models/profile_details.dart';
import 'backend_api_service.dart';

class ProfileApiService {
  ProfileApiService({BackendApiService? apiService})
    : _apiService = apiService ?? BackendApiService();

  final BackendApiService _apiService;

  Future<ProfileDetails> fetchMyProfile() async {
    final response = await _apiService.get('/users/me/profile');
    final profileJson = response['profile'];

    if (profileJson is Map<String, dynamic>) {
      return ProfileDetails.fromJson(profileJson);
    }

    if (profileJson is Map) {
      return ProfileDetails.fromJson(Map<String, dynamic>.from(profileJson));
    }

    return const ProfileDetails.empty();
  }

  Future<ProfileDetails> updateMyProfile(ProfileDetails profile) async {
    final response = await _apiService.put(
      '/users/me/profile',
      body: profile.toApiJson(),
    );
    final profileJson = response['profile'];

    if (profileJson is Map<String, dynamic>) {
      return ProfileDetails.fromJson(profileJson);
    }

    if (profileJson is Map) {
      return ProfileDetails.fromJson(Map<String, dynamic>.from(profileJson));
    }

    throw const BackendApiException(
      'Profile payload was missing from the backend response.',
    );
  }
}
