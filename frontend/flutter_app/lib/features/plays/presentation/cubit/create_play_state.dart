// lib/features/plays/presentation/cubit/create_play_state.dart
import 'package:equatable/equatable.dart';

enum CreatePlayStatus { initial, loading, success, failure }

class CreatePlayState extends Equatable {
  final CreatePlayStatus status;
  final String? errorMessage;

  const CreatePlayState({
    this.status = CreatePlayStatus.initial,
    this.errorMessage,
  });

  CreatePlayState copyWith({
    CreatePlayStatus? status,
    String? errorMessage,
  }) {
    return CreatePlayState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}