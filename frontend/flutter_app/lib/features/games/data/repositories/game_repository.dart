// lib/features/games/data/repositories/game_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/game_model.dart';

class GameRepository {
  final http.Client _client = http.Client();

  Future<List<Game>> getAllGames(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/');
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return body
            .map((json) => Game.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load games');
      }
    } catch (e) {
      throw Exception('Error fetching games: $e');
    }
  }

  Future<Game> getGameDetails({
    required String token,
    required int gameId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$gameId/');
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return Game.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load game details');
      }
    } catch (e) {
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
        return Game.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to schedule game. Server response: ${response.body}',
        );
      }
    } catch (e) {
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
        return Game.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update game.');
      }
    } catch (e) {
      throw Exception('Error updating game: $e');
    }
  }

  Future<void> deleteGame({required String token, required int gameId}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$gameId/');
    final response = await _client.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete game.');
    }
  }
}
