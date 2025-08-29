// lib/features/games/presentation/cubit/game_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/game_repository.dart';
import 'game_state.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class GameCubit extends Cubit<GameState> {
  final GameRepository _gameRepository;

  GameCubit({required GameRepository gameRepository})
    : _gameRepository = gameRepository,
      super(const GameState()) {
    logger.d('GameCubit: initialized.');
  }

  Future<void> fetchGames({required String token}) async {
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

    emit(state.copyWith(status: GameStatus.loading));
    logger.d('GameCubit: fetchGames started.');
    try {
      final games = await _gameRepository.getAllGames(token);
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

  void filterGamesByTeam(int? teamId) {
    // We can only filter if the fetch was successful
    if (state.status != GameStatus.success) return;

    if (teamId == null) {
      // If the filter is cleared (e.g., "All My Teams" is selected),
      // reset the filtered list to be the same as the master list.
      emit(state.copyWith(filteredGames: state.allGames));
      logger.d('GameCubit: filter cleared. Showing all ${state.allGames.length} games.');
    } else {
      // Filter the master list of allGames based on the selected teamId
      final filteredList = state.allGames.where((game) {
        return game.homeTeam.id == teamId || game.awayTeam.id == teamId;
      }).toList();

      // Emit a new state with the updated filteredGames list
      emit(state.copyWith(filteredGames: filteredList));
      logger.d('GameCubit: filter applied for team $teamId. ${filteredList.length} games remain.');
    }
  }
}
