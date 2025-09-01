// lib/features/games/data/repositories/game_repository.dart

// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:typed_data';
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
    bool includePossessions = false,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$gameId/').replace(
      queryParameters: includePossessions ? {'include_possessions': 'true'} : {},
    );
    logger.d('GameRepository: Fetching game details for $gameId (possessions: $includePossessions)');
    
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
      logger.e('GameRepository: Error fetching game $gameId: $e');
      throw Exception('Error fetching game details: $e');
    }
  }

  Future<Map<String, dynamic>> getGamePossessions({
    required String token,
    required int gameId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$gameId/possessions/').replace(
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );
    logger.d('GameRepository: Fetching possessions for game $gameId, page $page');
    
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        logger.i('GameRepository: Loaded ${data['results'].length} possessions for game $gameId');
        return data;
      } else {
        logger.e('GameRepository: Failed to load possessions for game $gameId. Status: ${response.statusCode}');
        throw Exception('Failed to load possessions');
      }
    } catch (e) {
      logger.e('GameRepository: Error fetching possessions for game $gameId: $e');
      throw Exception('Error fetching possessions: $e');
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

  // Cache for comprehensive analytics (5 minutes)
  static final Map<String, Map<String, dynamic>> _analyticsCache = {};
  static final Map<String, DateTime> _analyticsCacheTime = {};

  Future<Map<String, dynamic>> getComprehensiveAnalytics({
    required String token,
    int? teamId,
    int? quarter,
    int? lastGames,
    String? outcome,
    String? homeAway,
    int? minPossessions,
  }) async {
    final queryParams = <String, String>{};
    
    if (teamId != null) queryParams['team_id'] = teamId.toString();
    if (quarter != null) queryParams['quarter'] = quarter.toString();
    if (lastGames != null) queryParams['last_games'] = lastGames.toString();
    if (outcome != null) queryParams['outcome'] = outcome;
    if (homeAway != null) queryParams['home_away'] = homeAway;
    if (minPossessions != null) queryParams['min_possessions'] = minPossessions.toString();
    
    // Create cache key
    final cacheKey = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    // Check cache
    final now = DateTime.now();
    if (_analyticsCache.containsKey(cacheKey)) {
      final cacheTime = _analyticsCacheTime[cacheKey];
      if (cacheTime != null && now.difference(cacheTime).inMinutes < 5) {
        logger.d('GameRepository: Returning cached comprehensive analytics');
        return _analyticsCache[cacheKey]!;
      }
    }
    
    final url = Uri.parse('${ApiClient.baseUrl}/games/comprehensive_analytics/').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    
    logger.d('GameRepository: Fetching comprehensive analytics with params: $queryParams');

    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        logger.i('GameRepository: Comprehensive analytics loaded successfully');
        final data = json.decode(response.body);
        
        // Cache the result
        _analyticsCache[cacheKey] = data;
        _analyticsCacheTime[cacheKey] = now;
        
        return data;
      } else {
        logger.e('GameRepository: Failed to load comprehensive analytics. Status: ${response.statusCode}');
        throw Exception('Failed to load comprehensive analytics');
      }
    } catch (e) {
      logger.e('GameRepository: Error fetching comprehensive analytics: $e');
      throw Exception('Error fetching comprehensive analytics: $e');
    }
  }

  Future<Map<String, dynamic>> exportAnalyticsPDF({
    required String token,
    int? teamId,
    int? quarter,
    int? lastGames,
    String? outcome,
    String? homeAway,
    int? minPossessions,
  }) async {
    final queryParams = <String, String>{};
    
    if (teamId != null) queryParams['team_id'] = teamId.toString();
    if (quarter != null) queryParams['quarter'] = quarter.toString();
    if (lastGames != null) queryParams['last_games'] = lastGames.toString();
    if (outcome != null) queryParams['outcome'] = outcome;
    if (homeAway != null) queryParams['home_away'] = homeAway;
    if (minPossessions != null) queryParams['min_possessions'] = minPossessions.toString();
    
    final url = Uri.parse('${ApiClient.baseUrl}/games/export_analytics_pdf/').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    
    logger.d('GameRepository: Exporting analytics PDF with params: $queryParams');

    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        logger.i('GameRepository: Analytics PDF exported successfully');
        return json.decode(response.body);
      } else {
        logger.e('GameRepository: Failed to export analytics PDF. Status: ${response.statusCode}');
        throw Exception('Failed to export analytics PDF');
      }
    } catch (e) {
      logger.e('GameRepository: Error exporting analytics PDF: $e');
      throw Exception('Error exporting analytics PDF: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getScoutingReports({
    required String token,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/scouting_reports/');
    
    logger.d('GameRepository: Fetching scouting reports');

    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        logger.i('GameRepository: Scouting reports loaded successfully');
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        logger.e('GameRepository: Failed to load scouting reports. Status: ${response.statusCode}');
        throw Exception('Failed to load scouting reports');
      }
    } catch (e) {
      logger.e('GameRepository: Error fetching scouting reports: $e');
      throw Exception('Error fetching scouting reports: $e');
    }
  }

  Future<Uint8List> downloadScoutingReport({
    required String token,
    required int reportId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$reportId/download_report/');
    
    logger.d('GameRepository: Downloading scouting report $reportId');

    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        logger.i('GameRepository: Scouting report downloaded successfully');
        return response.bodyBytes;
      } else {
        logger.e('GameRepository: Failed to download scouting report. Status: ${response.statusCode}');
        throw Exception('Failed to download scouting report');
      }
    } catch (e) {
      logger.e('GameRepository: Error downloading scouting report: $e');
      throw Exception('Error downloading scouting report: $e');
    }
  }

  Future<Map<String, dynamic>> renameScoutingReport({
    required String token,
    required int reportId,
    required String newTitle,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/$reportId/rename_report/');
    
    logger.d('GameRepository: Renaming scouting report $reportId to "$newTitle"');

    try {
      final response = await _client.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'title': newTitle}),
      );

      if (response.statusCode == 200) {
        logger.i('GameRepository: Scouting report renamed successfully');
        return json.decode(response.body);
      } else {
        logger.e('GameRepository: Failed to rename scouting report. Status: ${response.statusCode}');
        throw Exception('Failed to rename scouting report');
      }
    } catch (e) {
      logger.e('GameRepository: Error renaming scouting report: $e');
      throw Exception('Error renaming scouting report: $e');
    }
  }

  Future<Map<String, dynamic>> cleanupCorruptedReports({
    required String token,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/games/cleanup_corrupted_reports/');
    
    logger.d('GameRepository: Cleaning up corrupted reports');

    try {
      final response = await _client.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        logger.i('GameRepository: Corrupted reports cleaned up successfully');
        return json.decode(response.body);
      } else {
        logger.e('GameRepository: Failed to cleanup corrupted reports. Status: ${response.statusCode}');
        throw Exception('Failed to cleanup corrupted reports');
      }
    } catch (e) {
      logger.e('GameRepository: Error cleaning up corrupted reports: $e');
      throw Exception('Error cleaning up corrupted reports: $e');
    }
  }

  /// Clear the analytics cache
  static void clearAnalyticsCache() {
    try {
      _analyticsCache.clear();
      _analyticsCacheTime.clear();
      logger.d('GameRepository: Analytics cache cleared');
    } catch (e) {
      logger.w('GameRepository: Error clearing analytics cache: $e');
      // Reinitialize the cache maps if they're corrupted
      try {
        _analyticsCache.clear();
        _analyticsCacheTime.clear();
      } catch (e2) {
        logger.e('GameRepository: Failed to reinitialize analytics cache: $e2');
      }
    }
  }
}
