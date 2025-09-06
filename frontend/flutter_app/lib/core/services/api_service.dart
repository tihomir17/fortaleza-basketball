// lib/core/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fortaleza_basketball_analytics/core/api/api_client.dart';
import 'package:fortaleza_basketball_analytics/main.dart';

class ApiService {
  final http.Client _client = http.Client();
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ApiClient.baseUrl}$endpoint');
    logger.d('ApiService: GET request to $url');
    logger.d('ApiService: Auth token present: ${_authToken != null}');
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
      logger.d('ApiService: Added Authorization header');
    } else {
      logger.w('ApiService: No auth token available');
    }

    try {
      final response = await _client.get(url, headers: headers);
      logger.d('ApiService: Response status=${response.statusCode}');
      return response;
    } catch (e) {
      logger.e('ApiService: Error during GET request: $e');
      rethrow;
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiClient.baseUrl}$endpoint');
    logger.d('ApiService: POST request to $url');
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: json.encode(data),
      );
      logger.d('ApiService: Response status=${response.statusCode}');
      return response;
    } catch (e) {
      logger.e('ApiService: Error during POST request: $e');
      rethrow;
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiClient.baseUrl}$endpoint');
    logger.d('ApiService: PUT request to $url');
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    try {
      final response = await _client.put(
        url,
        headers: headers,
        body: json.encode(data),
      );
      logger.d('ApiService: Response status=${response.statusCode}');
      return response;
    } catch (e) {
      logger.e('ApiService: Error during PUT request: $e');
      rethrow;
    }
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ApiClient.baseUrl}$endpoint');
    logger.d('ApiService: DELETE request to $url');
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    try {
      final response = await _client.delete(url, headers: headers);
      logger.d('ApiService: Response status=${response.statusCode}');
      return response;
    } catch (e) {
      logger.e('ApiService: Error during DELETE request: $e');
      rethrow;
    }
  }
}
