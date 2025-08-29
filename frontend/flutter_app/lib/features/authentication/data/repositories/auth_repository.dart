// lib/features/authentication/data/repositories/auth_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

import '../models/user_model.dart'; // <-- IMPORT THE PACKAGE

class AuthRepository {
  final http.Client _client = http.Client();
  static const String _tokenKey =
      'authToken'; // A key to identify our token in storage

  // This variable is now just a quick in-memory cache.
  // The source of truth is SharedPreferences.
  String? authToken;

  // Now saves the token to persistent storage
  Future<String?> login(String username, String password) async {
    final url = Uri.parse('${ApiClient.baseUrl}/auth/login/');
    logger.d('AuthRepository: Attempting login to $url');
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
        logger.i('AuthRepository: Login successful. Token saved.');
        return authToken;
      } else {
        logger.w('AuthRepository: Login failed with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('AuthRepository: Error during login: $e');
      return null;
    }
  }

  // Now removes the token from persistent storage
  Future<void> logout() async {
    logger.d('AuthRepository: Attempting logout.');
    authToken = null; // Clear the in-memory cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey); // Remove from persistent storage
    logger.i('AuthRepository: Logout successful. Token removed.');
  }

  // A method to read the token from storage on app startup
  Future<String?> tryToLoadToken() async {
    logger.d('AuthRepository: Attempting to load token from SharedPreferences.');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      authToken = token; // Load into the in-memory cache
      logger.i('AuthRepository: Token loaded successfully.');
    }
    else {
      logger.d('AuthRepository: No token found in SharedPreferences.');
    }
    return token;
  }

  Future<User?> getCurrentUser(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/auth/me/');
    logger.d('AuthRepository: Fetching current user from $url');
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
        logger.i('AuthRepository: Current user fetched successfully.');
        return User.fromJson(data);
      } else {
        // This can happen if the token is valid but expired
        logger.w('AuthRepository: Failed to fetch current user with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('AuthRepository: Error fetching current user: $e');
      return null;
    }
  }
}
