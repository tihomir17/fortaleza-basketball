// lib/features/plays/data/repositories/play_repository.dart

import 'dart:convert';
import 'package:fortaleza_basketball_analytics/features/plays/data/models/play_category_model.dart';
import 'package:http/http.dart' as http;
import 'package:fortaleza_basketball_analytics/core/api/api_client.dart';
import '../models/play_definition_model.dart';
import 'package:fortaleza_basketball_analytics/main.dart'; // Import for global logger

class PlayRepository {
  final http.Client _client = http.Client();

  Future<List<PlayDefinition>> getPlaysForTeam({
    required String token,
    required int teamId,
  }) async {
    // Note the new nested URL structure
    final url = Uri.parse('${ApiClient.baseUrl}/teams/$teamId/plays/');
    logger.d('PlayRepository: Fetching plays for team $teamId at $url');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        final List<PlayDefinition> plays = body
            .map((dynamic item) => PlayDefinition.fromJson(item))
            .toList();
        logger.i('PlayRepository: Loaded ${plays.length} plays for team $teamId.');
        return plays;
      }
      if (response.statusCode == 404) {
        logger.w('PlayRepository: Team $teamId not found (404). Returning empty play list. Body: ${response.body}');
        return [];
      }
      logger.e('PlayRepository: Failed to load playbook. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to load playbook');
    } catch (e) {
      logger.e('PlayRepository: Error fetching playbook: $e');
      throw Exception('An error occurred while fetching the playbook: $e');
    }
  }

  Future<PlayDefinition> createPlay({
    required String token,
    required String name,
    required String? description,
    required String playType,
    required int teamId,
    int? parentId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/plays/');
    logger.d('PlayRepository: Creating play "$name" at $url');

    try {
      // Build the request body map
      final Map<String, dynamic> requestBody = {
        'name': name,
        'description': description,
        'play_type': playType,
        'team': teamId,
        // Only include the 'parent' key if parentId is not null
        if (parentId != null) 'parent': parentId,
      };

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody), // Encode the map
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> body = json.decode(response.body);
        logger.i('PlayRepository: Play "$name" created successfully.');
        return PlayDefinition.fromJson(body);
      }
      if (response.statusCode == 403) {
        logger.e('PlayRepository: Forbidden creating play. Body: ${response.body}');
        throw Exception('Forbidden creating play: ${response.body}');
      }
      logger.e('PlayRepository: Failed to create play. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception(
        'Failed to create play. Server response: ${response.body}',
      );
    } catch (e) {
      logger.e('PlayRepository: Error creating play: $e');
      throw Exception('An error occurred while creating the play: $e');
    }
  }

  Future<void> deletePlay({required String token, required int playId}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/plays/$playId/');
    logger.d('PlayRepository: Deleting play $playId at $url');
    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      // 204 No Content is the standard success code for a DELETE request
      if (response.statusCode == 204) {
        logger.i('PlayRepository: Play $playId deleted successfully.');
        return;
      }
      if (response.statusCode == 403) {
        logger.e('PlayRepository: Forbidden deleting play $playId. Body: ${response.body}');
        throw Exception('Forbidden deleting play $playId: ${response.body}');
      }
      logger.e('PlayRepository: Failed to delete play $playId. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to delete play.');
    } catch (e) {
      logger.e('PlayRepository: Error deleting play $playId: $e');
      throw Exception('An error occurred while deleting the play: $e');
    }
  }

  Future<PlayDefinition> updatePlay({
    required String token,
    required int playId, // The ID of the play to update
    required String name,
    required String? description,
    required String playType,
    required int teamId,
    int? parentId,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/plays/$playId/',
    ); // The detail URL
    logger.d('PlayRepository: Updating play $playId at $url');

    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'description': description,
        'play_type': playType,
        'parent': parentId,
        'team': teamId,
      };

      final response = await _client.put(
        // Using PUT for a full update
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // 200 OK is the success code for PUT
        final Map<String, dynamic> body = json.decode(response.body);
        logger.i('PlayRepository: Play $playId updated successfully.');
        return PlayDefinition.fromJson(body);
      }
      if (response.statusCode == 403) {
        logger.e('PlayRepository: Forbidden updating play $playId. Body: ${response.body}');
        throw Exception('Forbidden updating play $playId: ${response.body}');
      }
      logger.e('PlayRepository: Failed to update play $playId. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception(
        'Failed to update play. Server response: ${response.body}',
      );
    } catch (e) {
      logger.e('PlayRepository: Error updating play $playId: $e');
      throw Exception('An error occurred while updating the play: $e');
    }
  }

  Future<List<PlayCategory>> getAllCategories(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/play-categories/');
    logger.d('PlayRepository: Fetching all play categories at $url');
    try {
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final bodyText = response.body;
        final dynamic decoded = json.decode(bodyText);
        List<dynamic> items;
        if (decoded is List) {
          items = decoded;
          logger.d('PlayRepository: Parsed top-level List with ${items.length} items.');
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['results'] is List) {
            items = decoded['results'] as List<dynamic>;
            logger.d('PlayRepository: Parsed List from "results" with ${items.length} items.');
          } else if (decoded['categories'] is List) {
            items = decoded['categories'] as List<dynamic>;
            logger.d('PlayRepository: Parsed List from "categories" with ${items.length} items.');
          } else {
            logger.e('PlayRepository: Unexpected JSON shape. Keys=${decoded.keys.toList()}');
            throw Exception('Unexpected categories payload shape. Expected List or keys [results|categories].');
          }
        } else {
          logger.e('PlayRepository: Unexpected JSON root type: ${decoded.runtimeType}');
          throw Exception('Unexpected categories payload type: ${decoded.runtimeType}');
        }
        logger.i('PlayRepository: Loaded ${items.length} categories.');
        return items.map((json) => PlayCategory.fromJson(json)).toList();
      } else {
        logger.e('PlayRepository: Failed to load play categories. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to load play categories. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      logger.e('PlayRepository: Error fetching play categories: $e');
      throw Exception('Error fetching play categories: $e');
    }
  }

  Future<List<PlayDefinition>> getGenericPlayTemplates(String token) async {
    // This points to our new, dedicated endpoint
    final url = Uri.parse('${ApiClient.baseUrl}/plays/templates/');
    logger.d('PlayRepository: Fetching generic play templates at $url');
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        logger.i('PlayRepository: Loaded ${body.length} generic play templates.');
        return body.map((json) => PlayDefinition.fromJson(json)).toList();
      } else {
        logger.e('PlayRepository: Failed to load generic play templates. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load generic play templates');
      }
    } catch (e) {
      logger.e('PlayRepository: Error fetching generic play templates: $e');
      throw Exception('Error fetching generic plays: $e');
    }
  }

  Future<List<PlayDefinition>> getPlayTemplates(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/plays/templates/');
    logger.d('PlayRepository: Fetching play templates at $url');
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        logger.i('PlayRepository: Loaded ${body.length} play templates.');
        return body.map((json) => PlayDefinition.fromJson(json)).toList();
      } else {
        logger.e('PlayRepository: Failed to load play templates. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load play templates');
      }
    } catch (e) {
      logger.e('PlayRepository: Error fetching play templates: $e');
      throw Exception('Error fetching play templates: $e');
    }
  }
}
