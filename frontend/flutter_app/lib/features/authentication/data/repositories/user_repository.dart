// lib/features/authentication/data/repositories/user_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/user_model.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class UserRepository {
  final http.Client _client = http.Client();

  Future<List<User>> searchUsers({
    required String token,
    required String query,
  }) async {
    logger.d('UserRepository: Searching users with query: $query');
    if (query.isEmpty) {
      logger.d('UserRepository: Empty query, returning empty list.');
      return []; // Don't search for nothing
    }

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
        logger.i('UserRepository: Search users successful. Found ${body.length} users.');
        return body.map((dynamic item) => User.fromJson(item)).toList();
      } else {
        logger.e('UserRepository: Failed to search users. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to search users.');
      }
    } catch (e) {
      logger.e('UserRepository: Error during user search: $e');
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
    logger.d('UserRepository: Updating user $userId at $url');
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
        logger.i('UserRepository: User $userId updated successfully.');
        return User.fromJson(json.decode(response.body));
      } else {
        logger.e('UserRepository: Failed to update user $userId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to update user. Server response: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('UserRepository: Error during user update: $e');
      throw Exception('An error occurred while updating user: $e');
    }
  }

  // ADD THIS NEW METHOD FOR COACHES
  Future<void> updateCoach({
    required String token,
    required int userId,
    required String firstName,
    required String lastName,
    required String coachType,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/users/$userId/');
    logger.d('UserRepository: Updating coach $userId at $url with type $coachType');
    try {
      final response = await _client.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'first_name': firstName,
          'last_name': lastName,
          'coach_type': coachType,
        }),
      );
      if (response.statusCode != 200) {
        logger.e('UserRepository: Failed to update coach $userId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to update coach. Server response: ${response.body}',
        );
      }
      logger.i('UserRepository: Coach $userId updated successfully.');
    } catch (e) {
      logger.e('UserRepository: Error during coach update: $e');
      throw Exception('An error occurred while updating coach: $e');
    }
  }
}
