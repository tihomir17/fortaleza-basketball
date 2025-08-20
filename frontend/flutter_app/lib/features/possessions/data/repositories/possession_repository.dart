// lib/features/possessions/data/repositories/possession_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/possession_model.dart';
import 'package:flutter/foundation.dart';

class PossessionRepository {
  final http.Client _client = http.Client();

  Future<Possession> createPossession({
    required String token,
    required int gameId,
    required int teamId, // Team with the possession
    required int opponentId,
    required String startTime,
    required int duration,
    required int quarter,
    required String outcome,
    required String offensiveSequence,
    required String defensiveSequence,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/possessions/');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'game_id': gameId,
          'team_id': teamId,
          'opponent_id': opponentId,
          'start_time_in_game': startTime,
          'duration_seconds': duration,
          'quarter': quarter,
          'outcome': outcome,
          'offensive_sequence': offensiveSequence,
          'defensive_sequence': defensiveSequence,
        }),
      );

      // --- START OF DEBUGGING LOGS ---
      if (kDebugMode) {
        // Only print in debug mode
        print("\n--- POSSESSION CREATE RESPONSE ---");
        print("Status Code: ${response.statusCode}");
        print("Raw JSON Body: ${response.body}");
        print("--- END RESPONSE ---\n");
      }

      if (response.statusCode == 201) {
        return Possession.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to create possession. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while creating possession: $e');
    }
  }

  Future<Possession> updatePossession({
    required String token,
    required int possessionId,
    // Pass all the editable fields
    required int teamId,
    required int opponentId,
    required int gameId,
    required String startTime,
    required int duration,
    required int quarter,
    required String outcome,
    required String offensiveSequence,
    required String defensiveSequence,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/possessions/$possessionId/');
    try {
      final response = await _client.put(
        // Use PUT for a full update
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'team_id': teamId,
          'opponent_id': opponentId,
          'game_id': gameId,
          'start_time_in_game': startTime,
          'duration_seconds': duration,
          'quarter': quarter,
          'outcome': outcome,
          'offensive_sequence': offensiveSequence,
          'defensive_sequence': defensiveSequence,
        }),
      );
      if (response.statusCode == 200) {
        return Possession.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to update possession. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while updating possession: $e');
    }
  }

  Future<void> deletePossession({
    required String token,
    required int possessionId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/possessions/$possessionId/');

    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      // 204 No Content is the standard success code for a DELETE request.
      if (response.statusCode != 204) {
        throw Exception(
          'Failed to delete possession. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while deleting the possession: $e');
    }
  }
}
