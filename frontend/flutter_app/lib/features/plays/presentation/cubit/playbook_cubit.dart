// lib/features/plays/presentation/cubit/playbook_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/play_definition_model.dart';
import '../../data/repositories/play_repository.dart';
import 'playbook_state.dart';
import 'package:fortaleza_basketball_analytics/main.dart'; // Import for global logger

class PlaybookCubit extends Cubit<PlaybookState> {
  final PlayRepository _playRepository;
  static const int defaultTemplatesTeamId = 1; // The ID for our generic plays

  PlaybookCubit({required PlayRepository playRepository})
    : _playRepository = playRepository,
      super(const PlaybookState());

  Future<void> fetchPlaysForTeam({
    required String token,
    required int teamId, // The specific team we are viewing
  }) async {
    logger.d('PlaybookCubit: fetchPlaysForTeam started for team $teamId.');

    emit(state.copyWith(status: PlaybookStatus.loading));
    try {
      // Fetch two lists of plays in parallel      
      final futureTeamPlays = _playRepository.getPlaysForTeam(token: token, teamId: teamId);
      final futureGenericPlays = _playRepository.getGenericPlayTemplates(token); // We will create this

      final results = await Future.wait([futureTeamPlays, futureGenericPlays]);

      final List<PlayDefinition> teamPlays = results[0];
      final List<PlayDefinition> genericPlays = results[1];

      logger.i('PlaybookCubit: Loaded ${teamPlays.length} team plays and ${genericPlays.length} generic plays.');
      // Combine the two lists.
      // We can add logic here to prevent duplicates if needed.
      final allPlays = [...teamPlays, ...genericPlays];
      logger.d('PlaybookCubit: Total combined plays: ${allPlays.length}.');
      emit(state.copyWith(status: PlaybookStatus.success, plays: allPlays));
    } catch (e) {
      logger.e('PlaybookCubit: Error loading plays: $e');
      emit(
        state.copyWith(
          status: PlaybookStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
