// lib/features/plays/presentation/cubit/create_play_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/play_repository.dart';
import 'create_play_state.dart';

class CreatePlayCubit extends Cubit<CreatePlayState> {
  final PlayRepository _playRepository;

  CreatePlayCubit({required PlayRepository playRepository})
      : _playRepository = playRepository,
        super(const CreatePlayState());

  Future<void> submitPlay({
    required String token,
    required String name,
    required String? description,
    required String playType,
    required int teamId,
  }) async {
    emit(state.copyWith(status: CreatePlayStatus.loading));
    try {
      await _playRepository.createPlay(
        token: token,
        name: name,
        description: description,
        playType: playType,
        teamId: teamId,
      );
      emit(state.copyWith(status: CreatePlayStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: CreatePlayStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}