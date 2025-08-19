// lib/features/games/data/repositories/game_repository.dart
import 'dart:convert';
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
        return body.map((json) => Game.fromJson(json)).toList();
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
}
