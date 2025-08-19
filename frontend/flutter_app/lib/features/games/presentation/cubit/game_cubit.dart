// lib/features/games/presentation/cubit/game_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/game_repository.dart';
import 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final GameRepository _gameRepository;

  GameCubit({required GameRepository gameRepository})
    : _gameRepository = gameRepository,
      super(const GameState());

  Future<void> fetchGames({required String token}) async {
    if (token.isEmpty) {
      emit(
        state.copyWith(
          status: GameStatus.failure,
          errorMessage: "Not authenticated.",
        ),
      );
      return;
    }

    emit(state.copyWith(status: GameStatus.loading));
    try {
      final games = await _gameRepository.getAllGames(token);
      emit(
        state.copyWith(
          status: GameStatus.success,
          allGames: games,
          filteredGames: games,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GameStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  void filterGamesByTeam(int? teamId) {
    // We can only filter if the fetch was successful
    if (state.status != GameStatus.success) return;

    if (teamId == null) {
      // If the filter is cleared (e.g., "All My Teams" is selected),
      // reset the filtered list to be the same as the master list.
      emit(state.copyWith(filteredGames: state.allGames));
    } else {
      // Filter the master list of allGames based on the selected teamId
      final filteredList = state.allGames.where((game) {
        return game.homeTeam.id == teamId || game.awayTeam.id == teamId;
      }).toList();

      // Emit a new state with the updated filteredGames list
      emit(state.copyWith(filteredGames: filteredList));
    }
  }
}
