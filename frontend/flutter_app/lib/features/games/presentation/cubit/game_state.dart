// lib/features/games/presentation/cubit/game_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/game_model.dart';

enum GameStatus { initial, loading, success, failure }

class GameState extends Equatable {
  final GameStatus status;
  final List<Game> allGames; // All games fetched from the API
  final List<Game> filteredGames; // The list currently being displayed
  final String? errorMessage;

  const GameState({
    this.status = GameStatus.initial,
    this.allGames = const <Game>[],
    this.filteredGames = const <Game>[], // Initialize as empty
    this.errorMessage,
  });

  GameState copyWith({
    GameStatus? status,
    List<Game>? allGames,
    List<Game>? filteredGames,
    String? errorMessage,
  }) {
    return GameState(
      status: status ?? this.status,
      allGames: allGames ?? this.allGames,
      filteredGames: filteredGames ?? this.filteredGames,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, allGames, filteredGames, errorMessage];
}
