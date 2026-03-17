import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parfum.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

List<Parfum> _filterAndRankPerfumes(Map<String, dynamic> args) {
  final List<dynamic> rawJsonList = args['perfumes'];
  final Set<String> selectedNotes = args['selectedNotes'] as Set<String>;

  final List<Parfum> allPerfumes = rawJsonList.map((e) => Parfum.fromJson(e)).toList();
  final List<Map<String, dynamic>> scoredPerfumes = [];

  for (var parfum in allPerfumes) {
    int score = 0;
    // Combine all notes into a single lowercase searchable string
    final combinedNotes = "${parfum.topNotes ?? ''} ${parfum.middleNotes ?? ''} ${parfum.baseNotes ?? ''}".toLowerCase();

    for (var note in selectedNotes) {
      if (combinedNotes.contains(note.toLowerCase())) {
        score++;
      }
    }

    if (score > 0) {
      scoredPerfumes.add({'parfum': parfum, 'score': score});
    }
  }

  // Sort by highest score first
  scoredPerfumes.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
  return scoredPerfumes.map((e) => e['parfum'] as Parfum).toList();
}

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

  static const String _finderCacheKey = 'cached_finder_brands';
  final List<String> _allowedBrands = [
    "French Avenue", "Afnan", "Armaf",
    "Lattafa", "Fragrance World", "Maison Alhambra"
  ];

  Future<List<Parfum>> getFinderResults(Set<String> selectedNotes) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_finderCacheKey);
    List<dynamic> allPerfumesJson = [];

    if (cachedData != null) {
      allPerfumesJson = json.decode(cachedData);
    } else {
      // 1. Parallel fetching using Future.wait
      try {
        final List<Future<List<dynamic>>> requests = _allowedBrands
            .map((brand) => _apiService.getFragrancesByBrand(brand))
            .toList();

        final results = await Future.wait(requests);

        // 2. Combine results
        for (var brandResults in results) {
          allPerfumesJson.addAll(brandResults);
        }

        // 3. Cache the combined list
        await prefs.setString(_finderCacheKey, json.encode(allPerfumesJson));
      } catch (e) {
        print("Error fetching finder brands: $e");
        return [];
      }
    }

    // 4. Offload heavy matching/ranking logic to a background Isolate
    return await compute(_filterAndRankPerfumes, {
      'perfumes': allPerfumesJson,
      'selectedNotes': selectedNotes,
    });
  }
}