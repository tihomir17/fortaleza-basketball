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
      emit(state.copyWith(status: GameStatus.success, games: games));
    } catch (e) {
      emit(
        state.copyWith(status: GameStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
