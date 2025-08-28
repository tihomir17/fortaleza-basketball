// lib/features/plays/presentation/cubit/playbook_cubit.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/play_definition_model.dart';
import '../../data/repositories/play_repository.dart';
import 'playbook_state.dart';

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
    if (kDebugMode) {
      print("\n--- PlaybookCubit: fetchPlaysForTeam ---");
      print("  - Fetching plays for SPECIFIC Team ID: $teamId");
      print("  - Fetching plays for GENERIC Team ID: $defaultTemplatesTeamId");
    }

    emit(state.copyWith(status: PlaybookStatus.loading));
    try {
      // Fetch two lists of plays in parallel      
      final futureTeamPlays = _playRepository.getPlaysForTeam(token: token, teamId: teamId);
      final futureGenericPlays = _playRepository.getGenericPlayTemplates(token); // We will create this

      final results = await Future.wait([futureTeamPlays, futureGenericPlays]);

      final List<PlayDefinition> teamPlays = results[0];
      final List<PlayDefinition> genericPlays = results[1];

      if (kDebugMode) {
        print("  - API call successful.");
        print("  - Received ${teamPlays.length} plays for Team ID $teamId.");
        print("  - Received ${genericPlays.length} plays for Generic Team ID $defaultTemplatesTeamId.");
      }
      // Combine the two lists.
      // We can add logic here to prevent duplicates if needed.
      final allPlays = [...teamPlays, ...genericPlays];
      if (kDebugMode) {
        print("  - Total combined plays: ${allPlays.length}. Emitting success state.");
        print("--- END PlaybookCubit ---\n");
      }
      emit(state.copyWith(status: PlaybookStatus.success, plays: allPlays));
    } catch (e) {
      if (kDebugMode) {
        print("  - AN ERROR OCCURRED in PlaybookCubit: $e");
        print("--- END PlaybookCubit (WITH ERROR) ---\n");
      }      
      emit(
        state.copyWith(
          status: PlaybookStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
