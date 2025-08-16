// lib/features/teams/presentation/cubit/team_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/team_repository.dart';
import 'team_state.dart';

class TeamCubit extends Cubit<TeamState> {
  final TeamRepository _teamRepository;

  TeamCubit({required TeamRepository teamRepository})
    : _teamRepository = teamRepository,
      super(const TeamState());

  // Only this method is needed.
  Future<void> fetchTeams({required String token}) async {
    emit(state.copyWith(status: TeamStatus.loading));
    try {
      final teams = await _teamRepository.getMyTeams(token: token);
      emit(state.copyWith(status: TeamStatus.success, teams: teams));
    } catch (e) {
      emit(
        state.copyWith(status: TeamStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
