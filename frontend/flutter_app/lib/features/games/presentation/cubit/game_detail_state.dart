// lib/features/games/presentation/cubit/game_detail_state.dart

import 'package:equatable/equatable.dart';
import 'package:fortaleza_basketball_analytics/features/possessions/data/models/possession_model.dart';
import '../../data/models/game_model.dart';

enum GameDetailStatus { initial, loading, success, failure }

class GameDetailState extends Equatable {
  final GameDetailStatus status;
  final Game? game; // Holds a single, detailed game object
  final String? errorMessage;

  const GameDetailState({
    this.status = GameDetailStatus.initial,
    this.game,
    this.errorMessage, 
  });

  GameDetailState copyWith({
    GameDetailStatus? status,
    Game? game,
    List<Possession>? filteredPossessions,
    String? errorMessage,
  }) {
    return GameDetailState(
      status: status ?? this.status,
      game: game ?? this.game,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, game, errorMessage];
}
