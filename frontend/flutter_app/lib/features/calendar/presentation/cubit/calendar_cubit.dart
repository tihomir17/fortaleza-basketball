// lib/features/calendar/presentation/cubit/calendar_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../games/data/repositories/game_repository.dart';
import '../../data/repositories/event_repository.dart'; // Create this repository
import 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final GameRepository _gameRepository;
  final EventRepository _eventRepository;

  CalendarCubit({
    required GameRepository gameRepository,
    required EventRepository eventRepository,
  })  : _gameRepository = gameRepository,
        _eventRepository = eventRepository,
        super(const CalendarState());

  Future<void> fetchCalendarData({required String token}) async {
    if (token.isEmpty) return;
    
    emit(state.copyWith(status: CalendarStatus.loading));
    try {
      // Fetch both sets of data in parallel
      final futureGames = _gameRepository.getAllGames(token);
      final futureEvents = _eventRepository.getAllEvents(token);

      // Wait for both API calls to complete
      final results = await Future.wait([futureGames, futureEvents]);

      // The results will be a list of lists, e.g., [[Game, Game], [Event, Event]]
      final games = results[0] as List<dynamic>;
      final events = results[1] as List<dynamic>;
      
      emit(state.copyWith(
        status: CalendarStatus.success,
        games: List.from(games), // Cast to the correct types
        events: List.from(events),
      ));
    } catch (e) {
      emit(state.copyWith(status: CalendarStatus.failure, errorMessage: e.toString()));
    }
  }
}