// lib/features/games/presentation/cubit/post_game_report_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fortaleza_basketball_analytics/main.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/game_repository.dart';
import 'post_game_report_state.dart';

class PostGameReportCubit extends Cubit<PostGameReportState> {
  final GameRepository _gameRepository;

  PostGameReportCubit({required GameRepository gameRepository})
      : _gameRepository = gameRepository,
        super(const PostGameReportState()) {
    logger.d('PostGameReportCubit: initialized.');
  }

  Future<void> fetchPostGameReport({
    required int gameId,
    required int teamId,
  }) async {
    emit(state.copyWith(status: PostGameReportStatus.loading));
    logger.d('PostGameReportCubit: fetchPostGameReport started.');

    try {
      final token = sl<AuthCubit>().state.token;
      if (token == null) {
        throw Exception('No authentication token available');
      }
      final report = await _gameRepository.getPostGameReport(
        token: token,
        gameId: gameId,
        teamId: teamId,
      );

      emit(
        state.copyWith(
          status: PostGameReportStatus.success,
          report: report,
        ),
      );
      logger.i('PostGameReportCubit: fetchPostGameReport succeeded.');
    } catch (e) {
      emit(
        state.copyWith(
          status: PostGameReportStatus.failure,
          errorMessage: e.toString(),
        ),
      );
      logger.e('PostGameReportCubit: fetchPostGameReport failed: $e');
    }
  }
}
