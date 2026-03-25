import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parfum.dart';
import '../models/accord_category.dart';
import 'api_service.dart';
import 'favorites_manager.dart';
import 'suggestions_seen_service.dart';

List<Parfum> _filterAndRankPerfumes(Map<String, dynamic> args) {
  final List<dynamic> rawJsonList = args['perfumes'];
  final Set<String> selectedNotes = Set<String>.from(
    args['selectedNotes'] as Set,
  );

  final List<Parfum> allPerfumes = rawJsonList
      .map((e) => Parfum.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  final List<Map<String, dynamic>> scoredPerfumes = [];

  for (final parfum in allPerfumes) {
    int score = 0;

    final combinedNotes =
        '${parfum.topNotes ?? ''} ${parfum.middleNotes ?? ''} ${parfum.baseNotes ?? ''} ${parfum.mainAccords ?? ''}'
            .toLowerCase();

    for (final note in selectedNotes) {
      if (combinedNotes.contains(note.toLowerCase())) {
        score++;
      }
    }

    if (score > 0) {
      scoredPerfumes.add({'parfum': parfum, 'score': score});
    }
  }

  scoredPerfumes.sort(
    (a, b) => (b['score'] as int).compareTo(a['score'] as int),
  );

  return scoredPerfumes.map((e) => e['parfum'] as Parfum).toList();
}

class CategoryFeedResult {
  final List<Parfum> perfumes;
  final bool exhausted;

  const CategoryFeedResult({required this.perfumes, required this.exhausted});
}

class DataRepository {
  final ApiService _apiService = ApiService();
  final SuggestionsSeenService _seenService = SuggestionsSeenService();

  static const String _tomFordCacheKey = 'cached_tom_ford_data_v2';
  static const String _homeAccordCacheKeyPrefix = 'cached_home_accord_';
  static const String _lattafaKey = 'cached_lattafa_data';
  static const String _finderCacheKey = 'cached_finder_brands_v2';

  final List<String> _allowedBrands = const [
    'French Avenue',
    'Afnan',
    'Armaf',
    'Lattafa',
    'Fragrance World',
    'Maison Alhambra',
  ];

  Future<List<Parfum>> getTomFordFragrances() async {
    try {
      return await getTomFordRecommendations(limit: 4);
    } catch (e) {
      debugPrint('Error fetching Tom Ford data: $e');
      return [];
    }
  }

  Future<List<Parfum>> getTomFordRecommendations({int limit = 4}) async {
    final prefs = await SharedPreferences.getInstance();

    final cachedData = prefs.getString(_tomFordCacheKey);
    if (cachedData != null) {
      final List<dynamic> decodedJson = json.decode(cachedData);
      return decodedJson
          .map((item) => Parfum.fromJson(Map<String, dynamic>.from(item)))
          .take(limit)
          .toList();
    }

    final apiResponse = await _apiService.getFragrancesByBrand(
      'Tom Ford',
      limit: 10,
    );

    final tomFordOnly = apiResponse
        .map((item) => Map<String, dynamic>.from(item))
        .where(
          (item) =>
              (item['Brand'] ?? '').toString().toLowerCase() == 'tom ford',
        )
        .take(limit)
        .toList();

    if (tomFordOnly.isNotEmpty) {
      await prefs.setString(_tomFordCacheKey, json.encode(tomFordOnly));
    }

    return tomFordOnly.map((item) => Parfum.fromJson(item)).toList();
  }

  Future<List<Parfum>> getAccordRecommendations({
    required AccordCategory category,
    int limit = 4,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_homeAccordCacheKeyPrefix${category.id}_$limit';
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      final List<dynamic> decodedJson = json.decode(cachedData);
      return decodedJson
          .map((item) => Parfum.fromJson(Map<String, dynamic>.from(item)))
          .take(limit)
          .toList();
    }

    final apiResponse = await _apiService.getMatchedFragrances(
      accords: '${category.apiAccord}:100',
      limit: limit,
    );
    final recommendations = apiResponse
        .map((item) => Map<String, dynamic>.from(item))
        .take(limit)
        .toList();

    if (recommendations.isNotEmpty) {
      await prefs.setString(cacheKey, json.encode(recommendations));
    }

    return recommendations.map((item) => Parfum.fromJson(item)).toList();
  }

  Future<List<Parfum>> getLattafaSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_lattafaKey);

    if (cachedData != null) {
      final List<dynamic> decoded = json.decode(cachedData);
      return decoded
          .map((item) => Parfum.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    try {
      final apiResponse = await _apiService.getFragrancesByBrand(
        'Lattafa',
        limit: 10,
      );

      final lattafaOnly = apiResponse
          .map((item) => Map<String, dynamic>.from(item))
          .where(
            (item) =>
                (item['Brand'] ?? '').toString().toLowerCase() == 'lattafa',
          )
          .take(10)
          .toList();

      if (lattafaOnly.isNotEmpty) {
        await prefs.setString(_lattafaKey, json.encode(lattafaOnly));
      }

      return lattafaOnly.map((item) => Parfum.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching Lattafa suggestions: $e');
      return [];
    }
  }

  Future<List<Parfum>> getFinderResults(Set<String> selectedNotes) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_finderCacheKey);

    List<dynamic> allPerfumesJson = [];

    if (cachedData != null) {
      allPerfumesJson = json.decode(cachedData);
    } else {
      try {
        final List<Future<List<dynamic>>> requests = _allowedBrands
            .map((brand) => _apiService.getFragrancesByBrand(brand, limit: 20))
            .toList();

        final results = await Future.wait(requests);

        for (final brandResults in results) {
          allPerfumesJson.addAll(
            brandResults.map((e) => Map<String, dynamic>.from(e)),
          );
        }

        await prefs.setString(_finderCacheKey, json.encode(allPerfumesJson));
      } catch (e) {
        debugPrint('Error fetching finder brands: $e');
        return [];
      }
    }

    return compute(_filterAndRankPerfumes, {
      'perfumes': allPerfumesJson,
      'selectedNotes': selectedNotes,
    });
  }

  Future<CategoryFeedResult> getAccordCategorySuggestions({
    required AccordCategory category,
    required FavoritesManager favoritesManager,
    int targetCount = 10,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final seenIds = await _seenService.getSeenIds(category.seenKey);
    final favoriteIds = favoritesManager.favorites
        .map((e) => e.stableKey)
        .toSet();

    final excludedKeys = <String>{...seenIds, ...favoriteIds};
    final collected = <Parfum>[];
    final collectedKeys = <String>{};

    for (final level in category.fallbackLevels) {
      if (collected.length >= targetCount) break;

      final raw = await _loadOrFetchAccordLevel(
        prefs: prefs,
        category: category,
        level: level,
      );

      final filtered = raw
          .map((e) => Parfum.fromJson(Map<String, dynamic>.from(e)))
          .where(_isPopularityAllowed)
          .where((p) => !excludedKeys.contains(p.stableKey))
          .where((p) => collectedKeys.add(p.stableKey))
          .toList();

      collected.addAll(filtered.take(targetCount - collected.length));
    }

    return CategoryFeedResult(
      perfumes: collected,
      exhausted: collected.isEmpty,
    );
  }

  Future<void> markCategorySeen({
    required AccordCategory category,
    required Parfum parfum,
  }) {
    return _seenService.markSeen(category.seenKey, parfum.stableKey);
  }

  bool _isPopularityAllowed(Parfum parfum) {
    final value = parfum.popularity?.trim().toLowerCase();
    return value == 'high' || value == 'very high';
  }

  Future<List<dynamic>> _loadOrFetchAccordLevel({
    required SharedPreferences prefs,
    required AccordCategory category,
    required int level,
  }) async {
    final cacheKey = 'cached_match_${category.id}_$level';
    final cached = prefs.getString(cacheKey);

    if (cached != null) {
      return json.decode(cached) as List<dynamic>;
    }

    final apiResponse = await _apiService.getMatchedFragrances(
      accords: '${category.apiAccord}:$level',
      limit: 10,
    );

    await prefs.setString(cacheKey, json.encode(apiResponse));
    return apiResponse;
  }
}
