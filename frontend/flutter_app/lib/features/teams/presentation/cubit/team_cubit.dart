// lib/features/teams/presentation/cubit/team_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/team_repository.dart';
import 'team_state.dart';
import 'package:fortaleza_basketball_analytics/main.dart'; // Import for global logger

class TeamCubit extends Cubit<TeamState> {
  final TeamRepository _teamRepository;
  DateTime? _lastFetchTime;
  static const Duration _minRefreshInterval = Duration(minutes: 5);

  TeamCubit({required TeamRepository teamRepository})
    : _teamRepository = teamRepository,
      super(const TeamState());

  Future<void> fetchTeams({required String token, bool forceRefresh = false}) async {
    // Check if we should skip the fetch (smart refresh)
    if (!forceRefresh && _shouldSkipFetch()) {
      logger.d('TeamCubit: Skipping fetch - data is recent enough');
      return;
    }

    emit(state.copyWith(status: TeamStatus.loading));
    logger.d('TeamCubit: fetchTeams started.');
    try {
      final teams = await _teamRepository.getMyTeams(token: token);
      _lastFetchTime = DateTime.now();
      emit(state.copyWith(status: TeamStatus.success, teams: teams));
      logger.i('TeamCubit: fetchTeams succeeded with ${teams.length} teams.');
    } catch (e) {
      emit(
        state.copyWith(status: TeamStatus.failure, errorMessage: e.toString()),
      );
      logger.e('TeamCubit: fetchTeams failed: $e');
    }
  }

  bool _shouldSkipFetch() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _minRefreshInterval;
  }
}
