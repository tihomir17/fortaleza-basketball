// lib/features/authentication/data/repositories/auth_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart'; // <-- IMPORT THE PACKAGE

class AuthRepository {
  final http.Client _client = http.Client();
  static const String _tokenKey =
      'authToken'; // A key to identify our token in storage

  // This variable is now just a quick in-memory cache.
  // The source of truth is SharedPreferences.
  String? authToken;

  // MODIFIED: Now saves the token to persistent storage
  Future<String?> login(String username, String password) async {
    final url = Uri.parse('${ApiClient.baseUrl}/auth/login/');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        authToken = data['access'];

        // Save to persistent storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, authToken!);

        return authToken;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // MODIFIED: Now removes the token from persistent storage
  Future<void> logout() async {
    authToken = null; // Clear the in-memory cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey); // Remove from persistent storage
  }

  // NEW: A method to read the token from storage on app startup
  Future<String?> tryToLoadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      authToken = token; // Load into the in-memory cache
    }
    return token;
  }

  Future<User?> getCurrentUser(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/auth/me/');
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        // This can happen if the token is valid but expired
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
