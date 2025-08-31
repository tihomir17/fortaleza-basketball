// lib/features/games/data/repositories/game_repository.dart

// ignore_for_file: unused_import

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/game_model.dart';
import '../models/post_game_report_model.dart';
import 'package:flutter_app/main.dart'; // Import for global logger
import 'package:flutter_app/core/logging/file_logger.dart';

class GameRepository {
  final http.Client _client = http.Client();
  
  // Enhanced in-memory cache for game lists
  static final Map<String, dynamic> _gameListCache = {};
  static DateTime _lastCacheTime = DateTime.now();
  static const Duration _cacheValidDuration = Duration(minutes: 10); // Increased cache duration

  Future<List<Game>> getAllGames(String token, {int page = 1, int pageSize = 50}) async {
    // Check cache first
    final cacheKey = 'games_list_${page}_${pageSize}_$token';
    if (_isCacheValid(cacheKey)) {
      logger.d('GameRepository: Returning cached games list for page $page');
      return _gameListCache[cacheKey] as List<Game>;
    }

    final url = Uri.parse('${ApiClient.baseUrl}/games/').replace(
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );
    logger.d('GameRepository: Fetching games list from $url');
    
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> items;
        
        // Handle paginated response
        if (decoded is Map<String, dynamic> && decoded['results'] != null) {
          items = decoded['results'] as List<dynamic>;
          logger.d('GameRepository: Parsed paginated response with ${items.length} games');
        } else if (decoded is List) {
          items = decoded;
          logger.d('GameRepository: Parsed direct list with ${items.length} games');
        } else {
          throw Exception('Unexpected response format');
        }
        
        final games = items
            .map((jsonItem) => Game.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
            
        // Cache the result
        _gameListCache[cacheKey] = games;
        _lastCacheTime = DateTime.now();
        
        logger.i('GameRepository: Loaded and cached ${games.length} games for page $page');
        return games;
      } else {
        logger.e('GameRepository: Failed to load games. Status: ${response.statusCode}');
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
    logger.d('GameRepository: Fetching game details for $gameId');
    
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        logger.i('GameRepository: Game $gameId details loaded successfully');
        
        final game = Game.fromJson(json.decode(response.body));
        return game;
      } else {
        logger.e('GameRepository: Failed to load game $gameId. Status: ${response.statusCode}');
        throw Exception('Failed to load game details');
      }
    } catch (e) {
      logger.e('GameRepository: Error fetching game $gameId details: $e');
      throw Exception('Error fetching game details: $e');
    }
  }

  // Cache management methods
  static bool _isCacheValid(String cacheKey) {
    if (!_gameListCache.containsKey(cacheKey)) return false;
    return DateTime.now().difference(_lastCacheTime) < _cacheValidDuration;
  }

  static void clearCache() {
    _gameListCache.clear();
    _lastCacheTime = DateTime.now();
    logger.d('GameRepository: Cache cleared');
  }

  static void invalidateCache() {
    _lastCacheTime = DateTime.now().subtract(_cacheValidDuration);
    logger.d('GameRepository: Cache invalidated');
  }

  Future<Game> createGame({
    required String token,
    required int competitionId,
    required int homeTeamId,
    required int awayTeamId,
    required DateTime gameDate,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/');
    logger.d('GameRepository: Creating game');
    
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
          'game_date': gameDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        logger.i('GameRepository: Game created successfully');
        // Invalidate cache since we added a new game
        invalidateCache();
        return Game.fromJson(json.decode(response.body));
      } else {
        logger.e('GameRepository: Failed to create game. Status: ${response.statusCode}');
        throw Exception('Failed to create game. Server response: ${response.body}');
      }
    } catch (e) {
      logger.e('GameRepository: Error creating game: $e');
      throw Exception('An error occurred while creating the game: $e');
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
    logger.d('GameRepository: Updating game $gameId');
    
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
        logger.i('GameRepository: Game $gameId updated successfully');
        // Invalidate cache since we modified a game
        invalidateCache();
        return Game.fromJson(json.decode(response.body));
      } else {
        logger.e('GameRepository: Failed to update game $gameId. Status: ${response.statusCode}');
        throw Exception('Failed to update game.');
      }
    } catch (e) {
      logger.e('GameRepository: Error updating game $gameId: $e');
      throw Exception('Error updating game: $e');
    }
  }

  Future<void> deleteGame({required String token, required int gameId}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$gameId/');
    logger.d('GameRepository: Deleting game $gameId');
    
    final response = await _client.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode != 204) {
      logger.e('GameRepository: Failed to delete game $gameId. Status: ${response.statusCode}');
      throw Exception('Failed to delete game.');
    }
    
    logger.i('GameRepository: Game $gameId deleted successfully');
    // Invalidate cache since we deleted a game
    invalidateCache();
  }

  Future<PostGameReport> getPostGameReport({
    required String token,
    required int gameId,
    required int teamId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$gameId/post-game-report/').replace(
      queryParameters: {
        'team_id': teamId.toString(),
      },
    );
    logger.d('GameRepository: Fetching post-game report for game $gameId, team $teamId');
    
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        logger.i('GameRepository: Post-game report loaded successfully');
        
        final report = PostGameReport.fromJson(json.decode(response.body));
        return report;
      } else {
        logger.e('GameRepository: Failed to load post-game report. Status: ${response.statusCode}');
        throw Exception('Failed to load post-game report');
      }
    } catch (e) {
      logger.e('GameRepository: Error fetching post-game report: $e');
      throw Exception('Error fetching post-game report: $e');
    }
  }
}
