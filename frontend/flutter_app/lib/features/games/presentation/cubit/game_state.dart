// lib/features/games/presentation/cubit/game_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/game_model.dart';

enum GameStatus { initial, loading, success, failure }

class GameState extends Equatable {
  final GameStatus status;
  final List<Game> games;
  final String? errorMessage;

  const GameState({
    this.status = GameStatus.initial,
    this.games = const <Game>[],
    this.errorMessage,
  });

  GameState copyWith({
    GameStatus? status,
    List<Game>? games,
    String? errorMessage,
  }) {
    return GameState(
      status: status ?? this.status,
      games: games ?? this.games,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, games, errorMessage];
}
