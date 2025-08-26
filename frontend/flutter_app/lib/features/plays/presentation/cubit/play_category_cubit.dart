import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/play_repository.dart';
import 'play_category_state.dart';

class PlayCategoryCubit extends Cubit<PlayCategoryState> {
  final PlayRepository _playRepository;

  PlayCategoryCubit({required PlayRepository playRepository})
    : _playRepository = playRepository,
      super(const PlayCategoryState());

  Future<void> fetchCategories({required String token}) async {
    if (token.isEmpty) {
      emit(
        state.copyWith(
          status: PlayCategoryStatus.failure,
          errorMessage: "Not authenticated.",
        ),
      );
      return;
    }

    emit(state.copyWith(status: PlayCategoryStatus.loading));
    try {
      final categories = await _playRepository.getAllCategories(token);
      emit(
        state.copyWith(
          status: PlayCategoryStatus.success,
          categories: categories,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PlayCategoryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
