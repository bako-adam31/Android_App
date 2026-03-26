import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendApiException implements Exception {
  final String message;
  final int? statusCode;

  const BackendApiException(this.message, {this.statusCode});

  @override
  String toString() => 'BackendApiException($statusCode): $message';
}

class BackendApiService {
  BackendApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:5001/api',
  );

  final http.Client _client;

  Future<Map<String, dynamic>> get(String path) {
    return _sendRequest(method: 'GET', path: path);
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) {
    return _sendRequest(method: 'PUT', path: path, body: body);
  }

  Future<Map<String, dynamic>> _sendRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const BackendApiException('No logged-in user');
    }

    final uri = Uri.parse('$_baseUrl$path');

    if (kDebugMode) {
      debugPrint('API $method $uri');
      debugPrint('Firebase UID: ${user.uid}');
    }

    var response = await _authorizedRequest(
      user: user,
      uri: uri,
      method: method,
      body: body,
      forceRefresh: false,
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      if (kDebugMode) {
        debugPrint('Retrying with fresh Firebase token');
      }

      response = await _authorizedRequest(
        user: user,
        uri: uri,
        method: method,
        body: body,
        forceRefresh: true,
      );
    }

    final decoded = response.body.trim().isEmpty
        ? <String, dynamic>{}
        : json.decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? (decoded['message']?.toString() ?? 'Request failed')
          : 'Request failed';
      throw BackendApiException(message, statusCode: response.statusCode);
    }

    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<http.Response> _authorizedRequest({
    required User user,
    required Uri uri,
    required String method,
    Map<String, dynamic>? body,
    required bool forceRefresh,
  }) async {
    final token = await user.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      throw const BackendApiException('Could not get Firebase ID token');
    }

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    if (method == 'GET') {
      return _client.get(uri, headers: headers);
    }

    if (method == 'PUT') {
      return _client.put(
        uri,
        headers: headers,
        body: json.encode(body ?? <String, dynamic>{}),
      );
    }

    throw BackendApiException('Unsupported method: $method');
  }
}
