// lib/features/competitions/presentation/cubit/competition_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/competition_model.dart';

enum CompetitionStatus { initial, loading, success, failure }

class CompetitionState extends Equatable {
  final CompetitionStatus status;
  final List<Competition> competitions;
  final String? errorMessage;

  const CompetitionState({
    this.status = CompetitionStatus.initial,
    this.competitions = const <Competition>[],
    this.errorMessage,
  });

  CompetitionState copyWith({
    CompetitionStatus? status,
    List<Competition>? competitions,
    String? errorMessage,
  }) {
    return CompetitionState(
      status: status ?? this.status,
      competitions: competitions ?? this.competitions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, competitions, errorMessage];
}
