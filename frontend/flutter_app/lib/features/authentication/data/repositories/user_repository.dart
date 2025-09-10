// lib/features/authentication/data/repositories/user_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fortaleza_basketball_analytics/core/api/api_client.dart';
import '../models/user_model.dart';
import 'package:fortaleza_basketball_analytics/main.dart'; // Import for global logger

class UserRepository {
  final http.Client _client = http.Client();

  Future<List<User>> searchUsers({
    required String token,
    required String query,
    String? role,
  }) async {
    logger.d('UserRepository: Searching users with query: $query');
    if (query.isEmpty) {
      logger.d('UserRepository: Empty query, returning empty list.');
      return []; // Don't search for nothing
    }

    final queryParams = {'search': query};
    if (role != null) {
      queryParams['role'] = role;
    }
    
    final url = Uri.parse(
      '${ApiClient.baseUrl}/auth/search/',
    ).replace(queryParameters: queryParams);

    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> items;
        
        // Handle different response formats
        if (decoded is List) {
          items = decoded;
          logger.d('UserRepository: Parsed direct list with ${items.length} users');
        } else if (decoded is Map<String, dynamic>) {
          // Handle paginated response or wrapped response
          if (decoded['results'] is List) {
            items = decoded['results'] as List<dynamic>;
            logger.d('UserRepository: Parsed paginated response with ${items.length} users');
          } else if (decoded['users'] is List) {
            items = decoded['users'] as List<dynamic>;
            logger.d('UserRepository: Parsed wrapped response with ${items.length} users');
          } else {
            logger.e('UserRepository: Unexpected JSON shape. Keys=${decoded.keys.toList()}');
            throw Exception('Unexpected search response format. Expected List or keys [results|users].');
          }
        } else {
          logger.e('UserRepository: Unexpected JSON root type: ${decoded.runtimeType}');
          throw Exception('Unexpected search response type: ${decoded.runtimeType}');
        }
        
        logger.i('UserRepository: Search users successful. Found ${items.length} users.');
        return items.map((dynamic item) => User.fromJson(item as Map<String, dynamic>)).toList();
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
    final primaryUrl = Uri.parse('${ApiClient.baseUrl}/users/$userId/');
    final fallbackUrl = Uri.parse('${ApiClient.baseUrl}/auth/users/$userId/');
    logger.d('UserRepository: Updating user $userId at $primaryUrl');
    try {
      final Map<String, dynamic> body = {
        'first_name': firstName,
        'last_name': lastName,
        if (jerseyNumber != null) 'jersey_number': jerseyNumber,
      };

      Future<http.Response> send(Uri url) {
        return _client.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(body),
        );
      }

      http.Response response = await send(primaryUrl);
      if (response.statusCode == 404) {
        logger.w('UserRepository: /users/ returned 404 for $userId, retrying /auth/users/.');
        response = await send(fallbackUrl);
      }
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
    final primaryUrl = Uri.parse('${ApiClient.baseUrl}/users/$userId/');
    final fallbackUrl = Uri.parse('${ApiClient.baseUrl}/auth/users/$userId/');
    logger.d('UserRepository: Updating coach $userId at $primaryUrl with type $coachType');
    try {
      final Map<String, dynamic> body = {
        'first_name': firstName,
        'last_name': lastName,
        'coach_type': coachType,
      };

      Future<http.Response> send(Uri url) {
        return _client.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(body),
        );
      }

      http.Response response = await send(primaryUrl);
      if (response.statusCode == 404) {
        logger.w('UserRepository: /users/ returned 404 for $userId, retrying /auth/users/.');
        response = await send(fallbackUrl);
      }
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
