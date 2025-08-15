// lib/features/teams/presentation/cubit/team_detail_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/team_model.dart';

enum TeamDetailStatus { initial, loading, success, failure }

class TeamDetailState extends Equatable {
  final TeamDetailStatus status;
  final Team? team; // <-- Holds a single team, can be null
  final String? errorMessage;

  const TeamDetailState({
    this.status = TeamDetailStatus.initial,
    this.team,
    this.errorMessage,
  });

  TeamDetailState copyWith({
    TeamDetailStatus? status,
    Team? team,
    String? errorMessage,
  }) {
    return TeamDetailState(
      status: status ?? this.status,
      team: team ?? this.team,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, team, errorMessage];
}