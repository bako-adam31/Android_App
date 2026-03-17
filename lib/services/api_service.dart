import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Your API Key from your Java code
  static const String _apiKey = "5b3e64ce4e87eeff555f1316d3f14a7f505e99068eef6dea83ddf47520bcb56f";
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

  Future<List<dynamic>> getFragrancesByBrand(String brand) async {
    final encodedBrand = Uri.encodeComponent(brand);
    // As per requirements: /brands/:brandName?limit=10
    final url = Uri.parse('$_baseUrl/brands/$encodedBrand?limit=10');

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch brand $brand: $e");
    }
  }
}