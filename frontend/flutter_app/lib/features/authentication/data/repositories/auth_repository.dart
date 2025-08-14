// lib/features/authentication/data/repositories/auth_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart'; // We created this earlier

class AuthRepository {
  final http.Client _client = http.Client();

  // We will need a way to store the token securely later.
  // For now, we'll just hold it in memory.
  String? authToken;

  // This method now returns the token on success and null on failure.
  Future<String?> login(String username, String password) async {
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
        authToken = data['access'];
        print('Login successful. Token acquired.');
        return authToken; // <-- Return the token string
      } else {
        print('Login failed: ${response.body}');
        return null; // <-- Return null on failure
      }
    } catch (e) {
      print('An error occurred during login: $e');
      return null; // <-- Return null on error
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