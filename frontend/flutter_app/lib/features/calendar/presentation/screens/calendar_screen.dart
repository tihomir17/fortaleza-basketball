// lib/features/calendar/presentation/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';
import 'package:intl/intl.dart';
import '../../../games/data/models/game_model.dart';
import '../../data/models/calendar_event_model.dart';
import '../cubit/calendar_cubit.dart';
import '../cubit/calendar_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // This function is the key. It gets called by the calendar for each day.
  List<dynamic> _getEventsForDay(DateTime day, CalendarState state) {
    // Filter the master list of games
    final gamesOnDay = state.games.where(
      (game) => isSameDay(game.gameDate, day),
    );
    // Filter the master list of events
    final eventsOnDay = state.events.where(
      (event) => isSameDay(event.startTime, day),
    );

    // Return a combined list
    return [...gamesOnDay, ...eventsOnDay];
  }

  void _onDaySelected(
    DateTime selectedDay,
    DateTime focusedDay,
    CalendarState state,
  ) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        // When a day is selected, update the list of events for that day
        _selectedEvents = _getEventsForDay(selectedDay, state);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserProfileAppBar(title: 'CALENDAR'),
      body: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          if (state.status == CalendarStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == CalendarStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'Error loading calendar.'),
            );
          }

          // When the state rebuilds (e.g., after the initial fetch),
          // ensure the selected day's events are updated.
          if (_selectedDay != null) {
            _selectedEvents = _getEventsForDay(_selectedDay!, state);
          }

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                // Pass the current state to the handlers
                onDaySelected: (selected, focused) =>
                    _onDaySelected(selected, focused, state),
                eventLoader: (day) => _getEventsForDay(day, state),
                // ... (calendar styling)
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedEvents.length,
                  itemBuilder: (context, index) {
                    final item = _selectedEvents[index];

                    // Use type checking to build the correct ListTile for each item
                    if (item is Game) {
                      return _buildGameTile(item);
                    } else if (item is CalendarEvent) {
                      return _buildEventTile(item);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          /* TODO: Navigate to a new "Schedule Event" screen */
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper widget to build a ListTile for a Game
  Widget _buildGameTile(Game game) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sports_basketball),
        title: Text(
          '${game.homeTeam.name} vs ${game.awayTeam.name}',
        ),
        subtitle: Text('Game at ${DateFormat.jm().format(game.gameDate)}'),
      ),
    );
  }

  // Helper widget to build a ListTile for a CalendarEvent
  Widget _buildEventTile(CalendarEvent event) {
    return Card(
      child: ListTile(
        leading: Icon(
          event.eventType == 'PRACTICE_TEAM' ? Icons.group : Icons.person,
        ),
        title: Text(event.title),
        subtitle: Text(
          'Practice at ${DateFormat.jm().format(event.startTime)}',
        ),
      ),
    );
  }
}
