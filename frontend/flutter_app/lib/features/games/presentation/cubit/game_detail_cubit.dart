// lib/features/games/presentation/cubit/game_detail_cubit.dart

import 'package:fortaleza_basketball_analytics/features/possessions/data/models/possession_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/models/game_model.dart';
import 'game_detail_state.dart';
import 'package:fortaleza_basketball_analytics/main.dart'; // Import for global logger

class GameDetailCubit extends Cubit<GameDetailState> {
  final GameRepository _gameRepository;
  
  // Cache for game details
  static final Map<int, Game> _gameCache = {};
  static final Map<int, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  GameDetailCubit({required GameRepository gameRepository})
    : _gameRepository = gameRepository,
      super(const GameDetailState());

  Future<void> fetchGameDetails({
    required String token,
    required int gameId,
    bool loadPossessions = false,
  }) async {
    emit(state.copyWith(status: GameDetailStatus.loading));
    logger.d('GameDetailCubit: fetchGameDetails started for game $gameId (possessions: $loadPossessions).');
    
    try {
      // Check cache first
      if (_isGameCached(gameId) && !loadPossessions) {
        logger.d('GameDetailCubit: Returning cached game $gameId');
        final cachedGame = _gameCache[gameId]!;
        emit(
          state.copyWith(
            status: GameDetailStatus.success,
            game: cachedGame,
            filteredPossessions: cachedGame.possessions,
          ),
        );
        return;
      }

      // Load game details (with or without possessions)
      final game = await _gameRepository.getGameDetails(
        token: token,
        gameId: gameId,
        includePossessions: loadPossessions,
      );

      // If possessions weren't loaded with the game, load them separately
      List<Possession> possessions = [];
      if (loadPossessions && game.possessions.isEmpty) {
        logger.d('GameDetailCubit: Loading possessions separately for game $gameId');
        final possessionsData = await _gameRepository.getGamePossessions(
          token: token,
          gameId: gameId,
          page: 1,
          pageSize: 50, // Load first 50 possessions
        );
        
        possessions = (possessionsData['results'] as List)
            .map((json) => Possession.fromJson(json))
            .toList();
        
        // Update game with loaded possessions
        game.possessions = possessions;
      } else {
        possessions = List<Possession>.from(game.possessions);
      }

      // Cache the game
      _gameCache[gameId] = game;
      _cacheTimestamps[gameId] = DateTime.now();

      // Log summary instead of individual possessions
      logger.i('GameDetailCubit: Loaded game $gameId with ${possessions.length} possessions');

      emit(
        state.copyWith(
          status: GameDetailStatus.success,
          game: game,
          filteredPossessions: possessions,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: GameDetailStatus.failure,
          errorMessage: e.toString(),
        ),
      );
      logger.e('GameDetailCubit: fetchGameDetails failed for game $gameId: $e');
    }
  }

  bool _isGameCached(int gameId) {
    final timestamp = _cacheTimestamps[gameId];
    if (timestamp == null) return false;
    
    final age = DateTime.now().difference(timestamp);
    return age < _cacheValidDuration;
  }

  void clearCache() {
    _gameCache.clear();
    _cacheTimestamps.clear();
    logger.d('GameDetailCubit: Cache cleared');
  }

  void clearGameCache(int gameId) {
    _gameCache.remove(gameId);
    _cacheTimestamps.remove(gameId);
    logger.d('GameDetailCubit: Cache cleared for game $gameId');
  }
}
