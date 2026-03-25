import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _apiKey =
      'fd8094dfde51e2499d3f92a850057230d6bc59e890a431e31cd42997c55e4930';
  static const String _baseUrl = 'https://api.fragella.com/api/v1';

  Future<List<dynamic>> getFragrancesByBrand(
    String brand, {
    int limit = 10,
  }) async {
    final encodedBrand = Uri.encodeComponent(brand);
    final url = Uri.parse('$_baseUrl/brands/$encodedBrand?limit=$limit');

    final response = await http.get(
      url,
      headers: {'x-api-key': _apiKey, 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load fragrances: ${response.statusCode} ${response.body}',
      );
    }

    return _extractList(response.body);
  }

  Future<List<dynamic>> searchFragrances(String query, {int limit = 20}) async {
    final encodedQuery = Uri.encodeQueryComponent(query.trim());
    final url = Uri.parse(
      '$_baseUrl/fragrances?limit=$limit&search=$encodedQuery',
    );

    final response = await http.get(
      url,
      headers: {'x-api-key': _apiKey, 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to search fragrances: ${response.statusCode} ${response.body}',
      );
    }

    return _extractList(response.body);
  }

  Future<List<dynamic>> getMatchedFragrances({
    required String accords,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/fragrances/match?limit=$limit&accords=${Uri.encodeQueryComponent(accords)}',
    );

    final response = await http.get(
      url,
      headers: {'x-api-key': _apiKey, 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch matched fragrances: ${response.statusCode} ${response.body}',
      );
    }

    return _extractList(response.body);
  }

  List<dynamic> _extractList(String rawBody) {
    final decoded = json.decode(rawBody);

    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'] as List<dynamic>;
    }
    if (decoded is Map<String, dynamic> && decoded['fragrances'] is List) {
      return decoded['fragrances'] as List<dynamic>;
    }
    if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      return decoded['results'] as List<dynamic>;
    }

    throw Exception('Unexpected API response format');
  }
}
