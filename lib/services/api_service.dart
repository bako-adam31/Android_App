import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Your API Key from your Java code
  static const String _apiKey = "fd8094dfde51e2499d3f92a850057230d6bc59e890a431e31cd42997c55e4930";
  static const String _baseUrl = "https://api.fragella.com/api/v1";

  static final Map<String, String> _headers = {
    'x-api-key': _apiKey,
  };

  // This is the method your DataRepository is trying to call
  Future<List<dynamic>> searchFragrances(String query) async {
    final encodedQuery = Uri.encodeComponent(query.trim());
    final url = Uri.parse('$_baseUrl/fragrances?limit=20&search=$encodedQuery');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        // Returns a list of JSON objects
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch from API: $e");
    }
  }
}