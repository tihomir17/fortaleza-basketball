// lib/features/plays/data/repositories/play_repository.dart

import 'dart:convert';
import 'package:flutter_app/features/plays/data/models/play_category_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/play_definition_model.dart';

class PlayRepository {
  final http.Client _client = http.Client();

  Future<List<PlayDefinition>> getPlaysForTeam({
    required String token,
    required int teamId,
  }) async {
    // Note the new nested URL structure
    final url = Uri.parse('${ApiClient.baseUrl}/teams/$teamId/plays/');

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
        return plays;
      } else {
        throw Exception('Failed to load playbook');
      }
    } catch (e) {
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
        return PlayDefinition.fromJson(body);
      } else {
        throw Exception(
          'Failed to create play. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while creating the play: $e');
    }
  }

  Future<void> deletePlay({required String token, required int playId}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/plays/$playId/');
    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      // 204 No Content is the standard success code for a DELETE request
      if (response.statusCode != 204) {
        throw Exception('Failed to delete play.');
      }
    } catch (e) {
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

    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'description': description,
        'play_type': playType,
        'parent': parentId,
        'team': teamId,
        // We must include the teamId, which the serializer requires
        // We'll get it from the original object on the edit screen.
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
        return PlayDefinition.fromJson(body);
      } else {
        throw Exception(
          'Failed to update play. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while updating the play: $e');
    }
  }
  
  Future<List<PlayCategory>> getAllCategories(String token) async {
  final url = Uri.parse('${ApiClient.baseUrl}/play-categories/');
  try {
    final response = await _client.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((json) => PlayCategory.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load play categories');
    }
  } catch (e) {
    throw Exception('Error fetching play categories: $e');
  }
}  
}
