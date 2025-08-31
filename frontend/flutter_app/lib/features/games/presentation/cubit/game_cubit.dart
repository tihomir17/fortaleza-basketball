// lib/features/games/presentation/cubit/game_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/models/game_model.dart';
import 'game_state.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class GameCubit extends Cubit<GameState> {
  final GameRepository _gameRepository;
  DateTime? _lastFetchTime;
  static const Duration _minRefreshInterval = Duration(seconds: 30);

  GameCubit({required GameRepository gameRepository})
    : _gameRepository = gameRepository,
      super(const GameState()) {
    logger.d('GameCubit: initialized.');
  }

  Future<void> fetchGames({required String token, bool forceRefresh = false}) async {
    if (token.isEmpty) {
      emit(
        state.copyWith(
          status: GameStatus.failure,
          errorMessage: "Not authenticated.",
        ),
      );
      logger.w('GameCubit: fetchGames blocked due to empty token.');
      return;
    }

    // Check if we should skip the fetch (smart refresh)
    if (!forceRefresh && _shouldSkipFetch()) {
      logger.d('GameCubit: Skipping fetch - data is recent enough');
      return;
    }

    emit(state.copyWith(status: GameStatus.loading));
    logger.d('GameCubit: fetchGames started.');
    
    try {
      final games = await _gameRepository.getAllGames(token);
      _lastFetchTime = DateTime.now();
      
      emit(
        state.copyWith(
          status: GameStatus.success,
          allGames: games,
          filteredGames: games,
        ),
      );
      logger.i('GameCubit: fetchGames succeeded with ${games.length} games.');
    } catch (e) {
      emit(
        state.copyWith(status: GameStatus.failure, errorMessage: e.toString()),
      );
      logger.e('GameCubit: fetchGames failed: $e');
    }
  }

  Future<void> refreshGames({required String token}) async {
    // Force refresh by clearing cache and fetching again
    GameRepository.clearCache();
    await fetchGames(token: token, forceRefresh: true);
  }

  bool _shouldSkipFetch() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _minRefreshInterval;
  }

  void applyAdvancedFilters({
    int? teamId,
    String? outcome,
    int? quarter,
    bool? showOnlyUserTeams,
    List<int>? userTeamIds,
    String? timeRange,
  }) {
    // We can only filter if the fetch was successful
    if (state.status != GameStatus.success) return;

    logger.d('GameCubit: Applying advanced filters - teamId: $teamId, outcome: $outcome, quarter: $quarter, showOnlyUserTeams: $showOnlyUserTeams, timeRange: $timeRange');

    List<Game> filteredList = List.from(state.allGames);

    // Filter by team
    if (teamId != null) {
      filteredList = filteredList.where((game) {
        return game.homeTeam?.id == teamId || game.awayTeam?.id == teamId;
      }).toList();
      logger.d('GameCubit: After team filter: ${filteredList.length} games');
    }

    // Filter by user teams only
    if (showOnlyUserTeams == true && userTeamIds != null && userTeamIds.isNotEmpty) {
      filteredList = filteredList.where((game) {
        return userTeamIds.contains(game.homeTeam?.id) || userTeamIds.contains(game.awayTeam?.id);
      }).toList();
      logger.d('GameCubit: After user teams filter: ${filteredList.length} games');
    }

    // Filter by outcome (W/L)
    if (outcome != null && outcome.isNotEmpty) {
      filteredList = filteredList.where((game) {
        // Only filter finished games
        if (game.homeTeamScore == null || game.awayTeamScore == null) {
          return false;
        }

        // Determine if the user's team is home or away
        int? userTeamId;
        if (teamId != null) {
          userTeamId = teamId;
        } else if (showOnlyUserTeams == true && userTeamIds != null && userTeamIds.isNotEmpty) {
          // Find which user team is in this game
          userTeamId = userTeamIds.firstWhere(
            (id) => game.homeTeam?.id == id || game.awayTeam?.id == id,
            orElse: () => -1,
          );
          if (userTeamId == -1) return false;
        } else {
          // If no specific team filter, we can't determine outcome
          return false;
        }

        final isHomeTeam = game.homeTeam?.id == userTeamId;
        final homeWon = game.homeTeamScore! > game.awayTeamScore!;
        final userWon = isHomeTeam ? homeWon : !homeWon;

        if (outcome == 'W') {
          return userWon;
        } else if (outcome == 'L') {
          return !userWon;
        }
        return true;
      }).toList();
      logger.d('GameCubit: After outcome filter ($outcome): ${filteredList.length} games');
    }

    // Filter by quarter
    if (quarter != null) {
      filteredList = filteredList.where((game) {
        // Check if any possession in this game is from the specified quarter
        return game.possessions.any((possession) => possession.quarter == quarter);
      }).toList();
      logger.d('GameCubit: After quarter filter (Q$quarter): ${filteredList.length} games');
    }

    // Filter by time range
    if (timeRange != null && timeRange.isNotEmpty) {
      final now = DateTime.now();
      DateTime? startDate;
      
      switch (timeRange) {
        case 'Last 7 Days':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Last 30 Days':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'Last 90 Days':
          startDate = now.subtract(const Duration(days: 90));
          break;
        case 'Season':
          // For season, we'll use a broader range (e.g., last 365 days)
          startDate = now.subtract(const Duration(days: 365));
          break;
      }
      
      if (startDate != null) {
        filteredList = filteredList.where((game) {
          // Only include games with a valid date that's within the time range
          return game.gameDate != null && game.gameDate!.isAfter(startDate!);
        }).toList();
        logger.d('GameCubit: After time range filter ($timeRange): ${filteredList.length} games');
      }
    }

    // Emit a new state with the updated filteredGames list
    emit(state.copyWith(filteredGames: filteredList));
    logger.i('GameCubit: Advanced filtering complete. ${filteredList.length} games remain.');
  }

  // Legacy method for backward compatibility
  void filterGamesByTeam(int? teamId) {
    applyAdvancedFilters(teamId: teamId);
  }

  // Clear cache when needed
  void clearCache() {
    GameRepository.clearCache();
    logger.d('GameCubit: Cache cleared');
  }
}
