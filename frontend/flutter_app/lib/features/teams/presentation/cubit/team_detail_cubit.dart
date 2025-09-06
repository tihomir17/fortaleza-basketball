// lib/features/teams/presentation/cubit/team_detail_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/team_repository.dart';
import 'team_detail_state.dart';
import 'package:fortaleza_basketball_analytics/main.dart'; // Import for global logger

class TeamDetailCubit extends Cubit<TeamDetailState> {
  final TeamRepository _teamRepository;

  TeamDetailCubit({required TeamRepository teamRepository})
    : _teamRepository = teamRepository,
      super(const TeamDetailState());

  Future<void> fetchTeamDetails({
    required String token,
    required int teamId,
  }) async {
    emit(state.copyWith(status: TeamDetailStatus.loading));
    logger.d('TeamDetailCubit: fetchTeamDetails started for team $teamId.');
    try {
      final team = await _teamRepository.getTeamDetails(
        token: token,
        teamId: teamId,
      );
      emit(state.copyWith(status: TeamDetailStatus.success, team: team));
      logger.i('TeamDetailCubit: fetchTeamDetails succeeded for team $teamId.');
    } catch (e) {
      emit(
        state.copyWith(
          status: TeamDetailStatus.failure,
          errorMessage: e.toString(),
        ),
      );
      logger.e('TeamDetailCubit: fetchTeamDetails failed for team $teamId: $e');
    }
  }
}
