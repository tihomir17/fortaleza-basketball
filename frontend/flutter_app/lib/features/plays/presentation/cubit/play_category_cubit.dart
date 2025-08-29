import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/play_repository.dart';
import 'play_category_state.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

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
      logger.w('PlayCategoryCubit: fetchCategories blocked due to empty token.');
      return;
    }

    emit(state.copyWith(status: PlayCategoryStatus.loading));
    logger.d('PlayCategoryCubit: fetchCategories started.');
    try {
      final categories = await _playRepository.getAllCategories(token);
      emit(
        state.copyWith(
          status: PlayCategoryStatus.success,
          categories: categories,
        ),
      );
      logger.i('PlayCategoryCubit: fetchCategories succeeded with ${categories.length} categories.');
    } catch (e) {
      emit(
        state.copyWith(
          status: PlayCategoryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
      logger.e('PlayCategoryCubit: fetchCategories failed: $e');
    }
  }
}
