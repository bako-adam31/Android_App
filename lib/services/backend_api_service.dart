import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendApiException implements Exception {
  final String message;
  final int? statusCode;

  const BackendApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'BackendApiException(statusCode: $statusCode, message: $message)';
}

class BackendApiService {
  BackendApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _defaultBaseUrl = 'http://localhost:5000/api';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  final http.Client _client;

  String get _baseUrl {
    if (_configuredBaseUrl != _defaultBaseUrl) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return _configuredBaseUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }

    return _configuredBaseUrl;
  }

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
      throw const BackendApiException('You must be logged in to continue.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.trim().isEmpty) {
      throw const BackendApiException('Could not retrieve an auth token.');
    }

    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    late final http.Response response;

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'PUT':
        response = await _client.put(
          uri,
          headers: headers,
          body: json.encode(body ?? <String, dynamic>{}),
        );
        break;
      default:
        throw BackendApiException('Unsupported HTTP method: $method');
    }

    final decoded = _decodeJson(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        _extractMessage(decoded) ??
            'Request failed with status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw const BackendApiException('Unexpected backend response format.');
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return json.decode(body);
    } catch (_) {
      throw const BackendApiException('Backend returned invalid JSON.');
    }
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map) {
      final message = decoded['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return null;
  }
}
