// lib/features/calendar/presentation/cubit/calendar_state.dart

import 'package:equatable/equatable.dart';
import '../../../games/data/models/game_model.dart';
import '../../data/models/calendar_event_model.dart'; // We will create this model

enum CalendarStatus { initial, loading, success, failure }

class CalendarState extends Equatable {
  final CalendarStatus status;
  // Hold the two separate lists of data
  final List<Game> games;
  final List<CalendarEvent> events;
  final String? errorMessage;

  const CalendarState({
    this.status = CalendarStatus.initial,
    this.games = const <Game>[],
    this.events = const <CalendarEvent>[],
    this.errorMessage,
  });

  // A helper getter to combine both lists into a single list of dynamic objects
  List<dynamic> get allCalendarItems {
    return [...games, ...events];
  }

  CalendarState copyWith({
    CalendarStatus? status,
    List<Game>? games,
    List<CalendarEvent>? events,
    String? errorMessage,
  }) {
    return CalendarState(
      status: status ?? this.status,
      games: games ?? this.games,
      events: events ?? this.events,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, games, events, errorMessage];
}