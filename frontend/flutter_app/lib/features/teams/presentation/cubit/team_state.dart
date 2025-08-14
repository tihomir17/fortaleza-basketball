// lib/features/teams/presentation/cubit/team_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/team_model.dart';

enum TeamStatus { initial, loading, success, failure }

class TeamState extends Equatable {
  final TeamStatus status;
  final List<Team> teams;
  final String? errorMessage;

  const TeamState({
    this.status = TeamStatus.initial,
    this.teams = const <Team>[],
    this.errorMessage,
  });

  TeamState copyWith({
    TeamStatus? status,
    List<Team>? teams,
    String? errorMessage,
  }) {
    return TeamState(
      status: status ?? this.status,
      teams: teams ?? this.teams,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, teams, errorMessage];
}