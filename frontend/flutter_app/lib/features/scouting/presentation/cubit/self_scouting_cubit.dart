// lib/features/scouting/presentation/cubit/self_scouting_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/self_scouting_data.dart';
import '../../data/services/self_scouting_service.dart';

// Events
abstract class SelfScoutingEvent extends Equatable {
  const SelfScoutingEvent();

  @override
  List<Object?> get props => [];
}

class LoadSelfScoutingData extends SelfScoutingEvent {
  const LoadSelfScoutingData();
}

class LoadMockSelfScoutingData extends SelfScoutingEvent {
  const LoadMockSelfScoutingData();
}

// States
abstract class SelfScoutingState extends Equatable {
  const SelfScoutingState();

  @override
  List<Object?> get props => [];
}

class SelfScoutingInitial extends SelfScoutingState {}

class SelfScoutingLoading extends SelfScoutingState {}

class SelfScoutingLoaded extends SelfScoutingState {
  final SelfScoutingData data;

  const SelfScoutingLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class SelfScoutingError extends SelfScoutingState {
  final String message;

  const SelfScoutingError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class SelfScoutingCubit extends Cubit<SelfScoutingState> {
  final SelfScoutingService _selfScoutingService;

  SelfScoutingCubit(this._selfScoutingService) : super(SelfScoutingInitial());

  Future<void> loadSelfScoutingData() async {
    try {
      emit(SelfScoutingLoading());
      
      final data = await _selfScoutingService.getSelfScoutingData();
      emit(SelfScoutingLoaded(data));
    } catch (e) {
      emit(SelfScoutingError(e.toString()));
    }
  }

  Future<void> loadMockSelfScoutingData() async {
    try {
      emit(SelfScoutingLoading());
      
      final data = await _selfScoutingService.getMockSelfScoutingData();
      emit(SelfScoutingLoaded(data));
    } catch (e) {
      emit(SelfScoutingError(e.toString()));
    }
  }
}
