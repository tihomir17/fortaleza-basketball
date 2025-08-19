// lib/features/games/presentation/cubit/game_detail_cubit.dart

import 'package:flutter_app/features/possessions/data/models/possession_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/game_repository.dart';
import 'game_detail_state.dart';

class GameDetailCubit extends Cubit<GameDetailState> {
  final GameRepository _gameRepository;

  GameDetailCubit({required GameRepository gameRepository})
    : _gameRepository = gameRepository,
      super(const GameDetailState());

  Future<void> fetchGameDetails({
    required String token,
    required int gameId,
  }) async {
    emit(state.copyWith(status: GameDetailStatus.loading));
    try {
      final game = await _gameRepository.getGameDetails(
        token: token,
        gameId: gameId,
      );

      // THIS IS THE FIX:
      // We explicitly cast the game.possessions to the correct type.
      // Even though it should already be correct, this satisfies the compiler's
      // strict type checking inside the copyWith method.
      final List<Possession> possessions = List<Possession>.from(
        game.possessions,
      );

      emit(
        state.copyWith(
          status: GameDetailStatus.success,
          game: game,
          // Pass the correctly typed list to the state
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
    }
  }
}
