import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parfum.dart';
import 'api_service.dart';

class DataRepository {
  final ApiService _apiService = ApiService();

  // The unique key for our saved data
  static const String _storageKey = 'cached_tom_ford_data';

  Future<List<Parfum>> getTomFordFragrances() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check if we already have the data saved locally
    final String? cachedData = prefs.getString(_storageKey);

    if (cachedData != null) {
      print("Loading Tom Ford data from LOCAL STORAGE! 🚀");
      // Decode the saved string back into a List of JSON objects
      List<dynamic> decodedJson = json.decode(cachedData);
      // Map it to our Dart model
      return decodedJson.map((item) => Parfum.fromJson(item)).toList();
    }

    // 2. If local storage is empty, call the API
    print("Local storage empty. Calling the API for Tom Ford... ⏳");
    try {
      // Searching the API for Tom Ford
      final apiResponse = await _apiService.searchFragrances("Tom Ford");

      // Filter the results to make absolutely sure the brand is Tom Ford
      final tomFordOnly = apiResponse.where((item) => item['Brand'] == 'Tom Ford').toList();

      // 3. Save this exact data to local storage so we never have to call the API again
      prefs.setString(_storageKey, json.encode(tomFordOnly));

      // Map it to our Dart model and return it
      return tomFordOnly.map((item) => Parfum.fromJson(item)).toList();

    } catch (e) {
      print("Error fetching data: $e");
      return []; // Return empty list on error
    }
  }

  static const String _lattafaKey = 'cached_lattafa_data';

  Future<List<Parfum>> getLattafaSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_lattafaKey);

    if (cachedData != null) {
      final List<dynamic> decoded = json.decode(cachedData);
      return decoded.map((item) => Parfum.fromJson(item)).toList();
    }

    try {
      final apiResponse = await _apiService.searchFragrances("Lattafa");

      final lattafaOnly = apiResponse
          .where((item) => item['Brand'] == 'Lattafa')
          .take(10)
          .toList();

      await prefs.setString(_lattafaKey, json.encode(lattafaOnly));

      return lattafaOnly.map((item) => Parfum.fromJson(item)).toList();
    } catch (e) {
      print("Error fetching Lattafa suggestions: $e");
      return [];
    }
  }
}