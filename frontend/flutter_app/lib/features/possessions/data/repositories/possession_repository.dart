// lib/features/possessions/data/repositories/possession_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/possession_model.dart';
import 'package:flutter_app/main.dart'; // Import for global logger
import 'package:flutter_app/core/logging/file_logger.dart';

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
    
    // Log the request data
    final requestData = {
      'game_id': gameId,
      'team_id': teamId,
      'opponent_id': opponentId,
      'start_time_in_game': startTime,
      'duration_seconds': duration,
      'quarter': quarter,
      'outcome': outcome,
      'offensive_sequence': offensiveSequence,
      'defensive_sequence': defensiveSequence,
    };
    
    await FileLogger().logPossessionData('createPossession', requestData);
    logger.d('PossessionRepository: Creating possession for game $gameId at $url');
    
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );

      // Log the API response
      await FileLogger().logApiResponse('/possessions/', response.statusCode, response.body);

      if (response.statusCode == 201) {
        logger.i('PossessionRepository: Possession created successfully for game $gameId.');
        final possession = Possession.fromJson(json.decode(response.body));
        
        // Log the created possession data
        await FileLogger().logPossessionData('createPossession_response', {
          'id': possession.id,
          'offensive_sequence': possession.offensiveSequence,
          'defensive_sequence': possession.defensiveSequence,
          'outcome': possession.outcome,
        });
        
        return possession;
      } else {
        logger.e('PossessionRepository: Failed to create possession. Status: ${response.statusCode}, Body: ${response.body}');
        await FileLogger().logError('createPossession_failed', 'Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to create possession. Server response: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('PossessionRepository: Error creating possession: $e');
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
    logger.d('PossessionRepository: Updating possession $possessionId at $url');
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
        logger.i('PossessionRepository: Possession $possessionId updated successfully.');
        return Possession.fromJson(json.decode(response.body));
      } else {
        logger.e('PossessionRepository: Failed to update possession $possessionId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to update possession. Server response: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('PossessionRepository: Error updating possession $possessionId: $e');
      throw Exception('An error occurred while updating possession: $e');
    }
  }

  Future<void> deletePossession({
    required String token,
    required int possessionId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/possessions/$possessionId/');

    logger.d('PossessionRepository: Deleting possession $possessionId at $url');
    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      // 204 No Content is the standard success code for a DELETE request.
      if (response.statusCode != 204) {
        logger.e('PossessionRepository: Failed to delete possession $possessionId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to delete possession. Server response: ${response.body}',
        );
      }
      logger.i('PossessionRepository: Possession $possessionId deleted successfully.');
    } catch (e) {
      logger.e('PossessionRepository: Error deleting possession $possessionId: $e');
      throw Exception('An error occurred while deleting the possession: $e');
    }
  }
}
