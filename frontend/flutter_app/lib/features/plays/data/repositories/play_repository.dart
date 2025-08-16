// lib/features/plays/data/repositories/play_repository.dart

import 'dart:convert';
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
    required String playType, // 'OFFENSIVE' or 'DEFENSIVE'
    required int teamId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/plays/');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'play_type': playType,
          'team': teamId, // The API expects the primary key of the team
        }),
      );

      if (response.statusCode == 201) {
        // 201 Created is the success code for POST
        final Map<String, dynamic> body = json.decode(response.body);
        return PlayDefinition.fromJson(body);
      } else {
        // Try to parse the error message from the backend
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Failed to create play';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('An error occurred while creating the play: $e');
    }
  }
}
