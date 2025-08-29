// lib/features/games/data/repositories/game_repository.dart

// ignore_for_file: unused_import

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
      final status = response.statusCode;
      final bodyText = response.body;
      logger.d(
        'GameRepository: Response status=$status, body=${bodyText.length > 800 ? '${bodyText.substring(0, 800)}...<truncated>' : bodyText}',
      );
      if (status == 200) {
        final dynamic decoded = json.decode(bodyText);
        List<dynamic> items;
        String fromKey = '<top-level>';
        if (decoded is List) {
          items = decoded;
          logger.d(
            'GameRepository: Parsed top-level List with ${items.length} items.',
          );
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['results'] is List) {
            items = decoded['results'] as List<dynamic>;
            fromKey = 'results';
          } else if (decoded['games'] is List) {
            items = decoded['games'] as List<dynamic>;
            fromKey = 'games';
          } else {
            // Fallback: pick the first List-valued entry
            final listEntry = decoded.entries.firstWhere(
              (e) => e.value is List,
              orElse: () => const MapEntry<String, dynamic>('#none', null),
            );
            if (listEntry.key != '#none') {
              items = (listEntry.value as List).cast<dynamic>();
              fromKey = listEntry.key;
              logger.w(
                'GameRepository: Using fallback list at key "$fromKey" with ${items.length} items. Keys=${decoded.keys.toList()}',
              );
            } else {
              logger.e(
                'GameRepository: Unexpected JSON shape. Keys=${decoded.keys.toList()}',
              );
              throw Exception(
                'Unexpected games payload shape. Expected List or a List under a map key.',
              );
            }
          }
          logger.d(
            'GameRepository: Parsed List from "$fromKey" with ${items.length} items.',
          );
        } else {
          logger.e(
            'GameRepository: Unexpected JSON root type: ${decoded.runtimeType}',
          );
          throw Exception(
            'Unexpected games payload type: ${decoded.runtimeType}',
          );
        }
        final games = items
            .map((jsonItem) => Game.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
        logger.i('GameRepository: Loaded ${games.length} games.');
        return games;
      } else {
        logger.e(
          'GameRepository: Failed to load games. Status: ${response.statusCode}, Body: ${response.body}',
        );
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
        logger.e(
          'GameRepository: Failed to load game $gameId. Status: ${response.statusCode}, Body: ${response.body}',
        );
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

      if (response.statusCode == 201) {
        logger.i('GameRepository: Game created successfully.');
        return Game.fromJson(json.decode(response.body));
      } else {
        logger.e(
          'GameRepository: Failed to schedule game. Status: ${response.statusCode}, Body: ${response.body}',
        );
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
        logger.e(
          'GameRepository: Failed to update game $gameId. Status: ${response.statusCode}, Body: ${response.body}',
        );
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
      logger.e(
        'GameRepository: Failed to delete game $gameId. Status: ${response.statusCode}, Body: ${response.body}',
      );
      throw Exception('Failed to delete game.');
    }
    logger.i('GameRepository: Game $gameId deleted successfully.');
  }
}
