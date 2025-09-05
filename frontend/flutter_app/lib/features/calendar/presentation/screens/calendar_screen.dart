// lib/features/calendar/presentation/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_state.dart';
import 'package:flutter_app/features/calendar/presentation/screens/edit_event_screen.dart';
import 'package:flutter_app/features/games/presentation/screens/schedule_game_screen.dart';
import 'package:flutter_app/features/games/data/repositories/game_repository.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart'; // Import for navigation
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/calendar/data/repositories/event_repository.dart';

import 'schedule_event_screen.dart';
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
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _refreshSignal.addListener(_refreshCalendar);
  }

  @override
  void dispose() {
    _refreshSignal.removeListener(_refreshCalendar);
    super.dispose();
  }

  void _refreshCalendar() {
    final token = context.read<AuthCubit>().state.token;
    if (token != null && mounted) {
      context.read<CalendarCubit>().fetchCalendarData(token: token);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day, CalendarState state) {
    final gamesOnDay = state.games.where(
      (game) => isSameDay(game.gameDate, day),
    );
    final eventsOnDay = state.events.where(
      (event) => isSameDay(event.startTime, day),
    );
    return [...gamesOnDay, ...eventsOnDay]..sort((a, b) {
      final timeA = a is Game ? a.gameDate : (a as CalendarEvent).startTime;
      final timeB = b is Game ? b.gameDate : (b as CalendarEvent).startTime;
      return timeA.compareTo(timeB);
    });
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
        _selectedEvents = _getEventsForDay(selectedDay, state);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserProfileAppBar(
        title: 'CALENDAR',
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState.status == AuthStatus.authenticated && 
                  authState.user != null) {
                
                final user = authState.user!;
                if (user.role == 'PLAYER') {
                  // Players cannot request individual practice sessions (disabled as per requirements)
                  return const SizedBox.shrink();
                } else {
                  // Coaches can schedule games and events directly
                  return IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Schedule Game or Event',
                    onPressed: () {
                      // The logic for showing the choice dialog remains the same
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.sports_basketball_outlined),
                              title: const Text('Schedule a New Game'),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ScheduleGameScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.event),
                              title: const Text('Schedule an Event'),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ScheduleEventScreen(
                                      initialDate: _selectedDay ?? DateTime.now(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
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
                onDaySelected: (selected, focused) =>
                    _onDaySelected(selected, focused, state),
                eventLoader: (day) => _getEventsForDay(day, state),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: _buildEventsMarker(events),
                      );
                    }
                    return null;
                  },
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),

                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _selectedEvents.isEmpty
                    ? const Center(
                        child: Text("No events scheduled for this day."),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),

                        itemCount: _selectedEvents.length,
                        itemBuilder: (context, index) {
                          final item = _selectedEvents[index];
                          if (item is Game) return _buildGameTile(item);
                          if (item is CalendarEvent) {
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
    );
  }

  Widget _buildEventsMarker(List<dynamic> events) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle(color: Colors.white, fontSize: 10.0),
        ),
      ),
    );
  }

  Widget _buildGameTile(Game game) {
    final theme = Theme.of(context);
    final isFinished = game.homeTeamScore != null && game.awayTeamScore != null;

    // Determine Win/Loss state for one of the user's teams
    final userTeams = context.read<TeamCubit>().state.teams;
    final userTeamInGame = userTeams.firstWhere(
      (t) => t.id == game.homeTeam.id || t.id == game.awayTeam.id);

    Color resultColor =
        theme.colorScheme.primary; // Default color for scheduled games
    String resultLetter = " ";
    if (isFinished && userTeamInGame != null) {
      bool homeTeamWon = game.homeTeamScore! > game.awayTeamScore!;
      bool didUserTeamWin =
          (userTeamInGame.id == game.homeTeam.id && homeTeamWon) ||
          (userTeamInGame.id == game.awayTeam.id && !homeTeamWon);
      resultColor = didUserTeamWin
          ? Colors.green.shade700
          : theme.colorScheme.error;
      resultLetter = didUserTeamWin ? "W" : "L";
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: resultColor,
          child: Text(
            resultLetter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${game.homeTeam.name} vs ${game.awayTeam.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: isFinished
            ? Text(
                'Final: ${game.homeTeamScore} - ${game.awayTeamScore}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              )
            : Text('Game at ${DateFormat.jm().format(game.gameDate)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              tooltip: 'View Game Details',
              onPressed: () => context.go('/games/${game.id}'),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Delete Game',
              onPressed: () => _showDeleteConfirmation(context, game),
            ),
          ],
        ),
        onTap: () => context.go('/games/${game.id}'),
      ),
    );
  }

  // THIS IS THE CORRECTED WIDGET FOR OTHER EVENTS
  Widget _buildEventTile(CalendarEvent event) {
    return Card(
      child: ListTile(
        leading: Icon(
          _getEventIcon(event.eventType),
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Starts at ${DateFormat.jm().format(event.startTime)}'),
        trailing: Builder(
          builder: (context) {
            final user = context.read<AuthCubit>().state.user;
            final isPlayer = user?.role == 'PLAYER';
            
            if (isPlayer) {
              // Players can only view events, no edit/delete buttons
              return const SizedBox.shrink();
            } else {
              // Coaches and other roles can edit/delete events
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit Event',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditEventScreen(event: event),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: 'Delete Event',
                    onPressed: () => _showDeleteConfirmation(context, event),
                  ),
                ],
              );
            }
          },
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _EventDetailScreen(event: event),
            ),
          );
        },
      ),
    );
  }

  // Helper method to get appropriate icon for event type
  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'PRACTICE_TEAM':
      case 'PRACTICE_INDIVIDUAL':
        return Icons.fitness_center;
      case 'SCOUTING_MEETING':
        return Icons.search;
      case 'STRENGTH_CONDITIONING':
        return Icons.sports_gymnastics;
      case 'GAME':
        return Icons.sports_basketball;
      case 'TEAM_MEETING':
        return Icons.groups;
      case 'TRAVEL_BUS':
        return Icons.directions_bus;
      case 'TRAVEL_PLANE':
        return Icons.flight;
      case 'TEAM_BUILDING':
        return Icons.emoji_events;
      default:
        return Icons.event;
    }
  }

  // A NEW, GENERIC DELETE CONFIRMATION DIALOG
  void _showDeleteConfirmation(BuildContext context, dynamic event) {
    final isGame = event is Game;
    final title = isGame ? 'Delete Game' : 'Delete Event';
    final content = isGame
        ? 'Are you sure you want to delete the game between ${event.homeTeam.name} and ${event.awayTeam.name}?'
        : 'Are you sure you want to delete the event "${event.title}"?';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text('$content This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () async {
                final token = context.read<AuthCubit>().state.token;
                if (token == null) return;
                try {
                  if (isGame) {
                    await sl<GameRepository>().deleteGame(
                      token: token,
                      gameId: event.id,
                    );
                  } else {
                    await sl<EventRepository>().deleteEvent(
                      token: token,
                      eventId: event.id,
                    );
                  }
                  Navigator.of(dialogContext).pop();
                  sl<RefreshSignal>().notify();
                } catch (e) {
                  // handle error
                }
              },
            ),
          ],
        );
      },
    );
  }

}

class _EventDetailScreen extends StatelessWidget {
  final CalendarEvent event;

  const _EventDetailScreen({required this.event});

  // Helper method to get appropriate icon for event type
  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'PRACTICE_TEAM':
      case 'PRACTICE_INDIVIDUAL':
        return Icons.fitness_center;
      case 'SCOUTING_MEETING':
        return Icons.search;
      case 'STRENGTH_CONDITIONING':
        return Icons.sports_gymnastics;
      case 'GAME':
        return Icons.sports_basketball;
      case 'TEAM_MEETING':
        return Icons.groups;
      case 'TRAVEL_BUS':
        return Icons.directions_bus;
      case 'TRAVEL_PLANE':
        return Icons.flight;
      case 'TEAM_BUILDING':
        return Icons.emoji_events;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          Builder(
            builder: (context) {
              final user = context.read<AuthCubit>().state.user;
              final isPlayer = user?.role == 'PLAYER';
              
              if (isPlayer) {
                // Players can only view events, no edit button
                return const SizedBox.shrink();
              } else {
                // Coaches and other roles can edit events
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditEventScreen(event: event),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  _getEventIcon(event.eventType),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(event.startTime)} at ${DateFormat.jm().format(event.startTime)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (event.description?.isNotEmpty == true) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                event.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
