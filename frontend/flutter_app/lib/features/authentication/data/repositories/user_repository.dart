// lib/features/authentication/data/repositories/user_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  final http.Client _client = http.Client();

  Future<List<User>> searchUsers({
    required String token,
    required String query,
  }) async {
    if (query.isEmpty) return []; // Don't search for nothing

    final url = Uri.parse(
      '${ApiClient.baseUrl}/auth/search/',
    ).replace(queryParameters: {'search': query});

    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => User.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search users.');
      }
    } catch (e) {
      throw Exception('An error occurred during user search: $e');
    }
  }

  Future<User> updateUser({
    required String token,
    required int userId,
    required String firstName,
    required String lastName,
    int? jerseyNumber,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/users/$userId/');
    try {
      final response = await _client.patch(
        // Use PATCH for partial updates
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'first_name': firstName,
          'last_name': lastName,
          'jersey_number': jerseyNumber,
        }),
      );
      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to update user. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while updating user: $e');
    }
  }
}
