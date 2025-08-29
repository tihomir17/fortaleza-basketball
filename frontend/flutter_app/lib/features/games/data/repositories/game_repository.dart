// lib/features/games/data/repositories/game_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/game_model.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class GameRepository {
  final http.Client _client = http.Client();

  Future<List<Game>> getAllGames(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/');
    logger.d('GameRepository: Fetching all games from $url');
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        logger.i('GameRepository: Loaded ${body.length} games.');
        return body
            .map((json) => Game.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        logger.e('GameRepository: Failed to load games. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load games');
      }
    } catch (e) {
      logger.e('GameRepository: Error fetching games: $e');
      throw Exception('Error fetching games: $e');
    }
  }

  Future<Game> getGameDetails({
    required String token,
    required int gameId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$gameId/');
    logger.d('GameRepository: Fetching game details for $gameId at $url');
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        logger.i('GameRepository: Game $gameId details loaded.');
        return Game.fromJson(json.decode(response.body));
      } else {
        logger.e('GameRepository: Failed to load game $gameId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load game details');
      }
    } catch (e) {
      logger.e('GameRepository: Error fetching game $gameId details: $e');
      throw Exception('Error fetching game details: $e');
    }
  }

  Future<Game> createGame({
    required String token,
    required int competitionId,
    required int homeTeamId,
    required int awayTeamId,
    required DateTime gameDate,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/');
    logger.d('GameRepository: Creating game at $url');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'competition': competitionId,
          'home_team': homeTeamId,
          'away_team': awayTeamId,
          // The backend expects a date in 'YYYY-MM-DD' format.
          'game_date': gameDate.toIso8601String(),
        }),
      );

      if (kDebugMode) {
        print("\n--- GAME CREATE RESPONSE ---");
        print("Status Code: ${response.statusCode}");
        print("Raw JSON Body: ${response.body}");
        print("--- END RESPONSE ---\n");
      }

      if (response.statusCode == 201) {
        logger.i('GameRepository: Game created successfully.');
        return Game.fromJson(json.decode(response.body));
      } else {
        logger.e('GameRepository: Failed to schedule game. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to schedule game. Server response: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('GameRepository: Error scheduling game: $e');
      throw Exception('An error occurred while scheduling the game: $e');
    }
  }

  Future<Game> updateGame({
    required String token,
    required int gameId,
    required int competitionId,
    required int homeTeamId,
    required int awayTeamId,
    required DateTime gameDate,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$gameId/');
    logger.d('GameRepository: Updating game $gameId at $url');
    try {
      final response = await _client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'competition': competitionId,
          'home_team': homeTeamId,
          'away_team': awayTeamId,
          'game_date': gameDate.toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        logger.i('GameRepository: Game $gameId updated successfully.');
        return Game.fromJson(json.decode(response.body));
      } else {
        logger.e('GameRepository: Failed to update game $gameId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to update game.');
      }
    } catch (e) {
      logger.e('GameRepository: Error updating game $gameId: $e');
      throw Exception('Error updating game: $e');
    }
  }

  Future<void> deleteGame({required String token, required int gameId}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$gameId/');
    logger.d('GameRepository: Deleting game $gameId at $url');
    final response = await _client.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      logger.e('GameRepository: Failed to delete game $gameId. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to delete game.');
    }
    logger.i('GameRepository: Game $gameId deleted successfully.');
  }
}
