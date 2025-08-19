// lib/features/games/presentation/cubit/game_detail_cubit.dart

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
      emit(state.copyWith(status: GameDetailStatus.success, game: game));
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
