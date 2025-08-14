// lib/features/authentication/data/repositories/auth_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart'; // We created this earlier

class AuthRepository {
  final http.Client _client = http.Client();

  // We will need a way to store the token securely later.
  // For now, we'll just hold it in memory.
  String? authToken;

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('${ApiClient.baseUrl}/auth/login/');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The token pair from djangorestframework-simplejwt is 'access' and 'refresh'
        authToken = data['access'];
        // In a real app, you would securely save this token to device storage.
        print('Login successful. Token: $authToken');
        return true;
      } else {
        // Handle login failure (e.g., wrong credentials)
        print('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print('An error occurred during login: $e');
      return false;
    }
  }

  void logout() {
    // Clear the token
    authToken = null;
    // In a real app, you would also clear the token from device storage.
  }

  bool isLoggedIn() {
    return authToken != null;
  }
}