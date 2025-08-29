// lib/features/plays/presentation/cubit/play_category_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/play_category_model.dart';

enum PlayCategoryStatus { initial, loading, success, failure }

class PlayCategoryState extends Equatable {
  final PlayCategoryStatus status;
  final List<PlayCategory> categories;
  final String? errorMessage;

  const PlayCategoryState({
    this.status = PlayCategoryStatus.initial,
    this.categories = const <PlayCategory>[],
    this.errorMessage,
  });

  PlayCategoryState copyWith({
    PlayCategoryStatus? status,
    List<PlayCategory>? categories,
    String? errorMessage,
  }) {
    return PlayCategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, categories, errorMessage];
}
