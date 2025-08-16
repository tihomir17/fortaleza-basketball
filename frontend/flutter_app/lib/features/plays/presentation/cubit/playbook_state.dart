// lib/features/plays/presentation/cubit/playbook_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/play_definition_model.dart';

enum PlaybookStatus { initial, loading, success, failure }

class PlaybookState extends Equatable {
  final PlaybookStatus status;
  final List<PlayDefinition> plays;
  final String? errorMessage;

  const PlaybookState({
    this.status = PlaybookStatus.initial,
    this.plays = const <PlayDefinition>[],
    this.errorMessage,
  });

  PlaybookState copyWith({
    PlaybookStatus? status,
    List<PlayDefinition>? plays,
    String? errorMessage,
  }) {
    return PlaybookState(
      status: status ?? this.status,
      plays: plays ?? this.plays,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, plays, errorMessage];
}