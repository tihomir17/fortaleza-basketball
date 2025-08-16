// lib/features/plays/presentation/cubit/playbook_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/play_repository.dart';
import 'playbook_state.dart';

class PlaybookCubit extends Cubit<PlaybookState> {
  final PlayRepository _playRepository;

  PlaybookCubit({required PlayRepository playRepository})
      : _playRepository = playRepository,
        super(const PlaybookState());

  Future<void> fetchPlays({required String token, required int teamId}) async {
    emit(state.copyWith(status: PlaybookStatus.loading));
    try {
      final plays = await _playRepository.getPlaysForTeam(token: token, teamId: teamId);
      emit(state.copyWith(status: PlaybookStatus.success, plays: plays));
    } catch (e) {
      emit(state.copyWith(status: PlaybookStatus.failure, errorMessage: e.toString()));
    }
  }
}