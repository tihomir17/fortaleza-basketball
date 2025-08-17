// lib/features/competitions/presentation/cubit/competition_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/competition_repository.dart';
import 'competition_state.dart';

class CompetitionCubit extends Cubit<CompetitionState> {
  final CompetitionRepository _competitionRepository;

  CompetitionCubit({required CompetitionRepository competitionRepository})
    : _competitionRepository = competitionRepository,
      super(const CompetitionState());

  Future<void> fetchCompetitions({required String token}) async {
    // Prevent fetching if a token is not available.
    if (token.isEmpty) {
      emit(
        state.copyWith(
          status: CompetitionStatus.failure,
          errorMessage: "Not authenticated.",
        ),
      );
      return;
    }

    emit(state.copyWith(status: CompetitionStatus.loading));
    try {
      final competitions = await _competitionRepository.getAllCompetitions(
        token,
      );
      emit(
        state.copyWith(
          status: CompetitionStatus.success,
          competitions: competitions,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CompetitionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
