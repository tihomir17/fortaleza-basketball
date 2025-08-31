// lib/features/games/presentation/cubit/post_game_report_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/post_game_report_model.dart';

enum PostGameReportStatus { initial, loading, success, failure }

class PostGameReportState extends Equatable {
  final PostGameReportStatus status;
  final PostGameReport? report;
  final String? errorMessage;

  const PostGameReportState({
    this.status = PostGameReportStatus.initial,
    this.report,
    this.errorMessage,
  });

  PostGameReportState copyWith({
    PostGameReportStatus? status,
    PostGameReport? report,
    String? errorMessage,
  }) {
    return PostGameReportState(
      status: status ?? this.status,
      report: report ?? this.report,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, report, errorMessage];
}
