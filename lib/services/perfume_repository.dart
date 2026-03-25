import '../models/perfume_details.dart';
import 'api_service.dart';

class PerfumeRepository {
  PerfumeRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<PerfumeDetails>> searchPerfumes(
    String query, {
    int limit = 8,
  }) async {
    final response = await _apiService.searchFragrances(query, limit: limit);
    final seenKeys = <String>{};

    return response
        .map((item) => PerfumeDetails.fromJson(Map<String, dynamic>.from(item)))
        .where((perfume) => seenKeys.add(perfume.stableKey))
        .toList();
  }

  Future<PerfumeDetails> getPerfumeDetails(PerfumeDetails perfume) async {
    if (perfume.hasRichDetails) {
      return perfume;
    }

    final candidates = await searchPerfumes(
      '${perfume.name} ${perfume.brand}',
      limit: 12,
    );

    for (final candidate in candidates) {
      if (candidate.matches(perfume)) {
        return candidate;
      }
    }

    return perfume;
  }
}
