import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_details.dart';

class ProfilePreferencesService {
  static const String _profileKeyPrefix = 'profile_details_';

  Future<ProfileDetails> getProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfile = prefs.getString(_storageKey(userId));

    if (rawProfile == null || rawProfile.trim().isEmpty) {
      return const ProfileDetails.empty();
    }

    try {
      final decoded = json.decode(rawProfile);
      if (decoded is Map<String, dynamic>) {
        return ProfileDetails.fromJson(decoded);
      }
      if (decoded is Map) {
        return ProfileDetails.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      await prefs.remove(_storageKey(userId));
    }

    return const ProfileDetails.empty();
  }

  Future<ProfileDetails> saveProfile(
    String userId,
    ProfileDetails profile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedProfile = ProfileDetails(
      bio: profile.bio.trim(),
      gender: profile.gender,
      favoriteAccord: profile.favoriteAccord,
      signatureFragrance: profile.signatureFragrance,
    );

    await prefs.setString(
      _storageKey(userId),
      json.encode(normalizedProfile.toJson()),
    );

    return normalizedProfile;
  }

  String _storageKey(String userId) => '$_profileKeyPrefix$userId';
}
