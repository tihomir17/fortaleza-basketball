// lib/features/games/presentation/screens/schedule_game_screen.dart

import 'package:flutter/material.dart';
import 'package:fortaleza_basketball_analytics/features/games/data/repositories/game_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fortaleza_basketball_analytics/core/navigation/refresh_signal.dart';
import 'package:fortaleza_basketball_analytics/main.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/competitions/presentation/cubit/competition_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/competitions/presentation/cubit/competition_state.dart';
import 'package:fortaleza_basketball_analytics/features/teams/data/models/team_model.dart';
import 'package:fortaleza_basketball_analytics/features/calendar/utils/calendar_validators.dart';

class ScheduleGameScreen extends StatefulWidget {
  const ScheduleGameScreen({super.key});

  @override
  State<ScheduleGameScreen> createState() => _ScheduleGameScreenState();
}

class _ScheduleGameScreenState extends State<ScheduleGameScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _gameDate = DateTime.now();
  TimeOfDay _gameTime = TimeOfDay.now();

  int? _selectedCompetitionId;
  List<Team> _teamsInCompetition = [];
  int? _selectedHomeTeamId;
  int? _selectedAwayTeamId;

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final finalGameTime = DateTime(
      _gameDate.year,
      _gameDate.month,
      _gameDate.day,
      _gameTime.hour,
      _gameTime.minute,
    );
    if (finalGameTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot schedule a game in the past.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final conflictError = CalendarValidators.validateNoConflicts(
      context: context,
      newStartTime: finalGameTime,
      newEndTime: finalGameTime.add(
        const Duration(hours: 2),
      ), // Assume a 2-hour game duration
    );

    if (conflictError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(conflictError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return; // Stop the submission if a conflict is found
    }
    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      // Handle error, maybe show a snackbar
      setState(() => _isLoading = false);
      return;
    }

    try {
      await sl<GameRepository>().createGame(
        token: token,
        competitionId: _selectedCompetitionId!,
        homeTeamId: _selectedHomeTeamId!,
        awayTeamId: _selectedAwayTeamId!,
        gameDate: finalGameTime,
      );

      if (mounted) {
        sl<RefreshSignal>().notify(); // Notify listeners to refresh data
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final competitionState = context.watch<CompetitionCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule New Game')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- SELECTION CARD ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Competition Selector
                    DropdownButtonFormField<int>(
                      value: _selectedCompetitionId,
                      hint: const Text('Select Competition *'),
                      items:
                          competitionState.status == CompetitionStatus.success
                          ? competitionState.competitions
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList()
                          : [],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCompetitionId = value;
                            _teamsInCompetition = competitionState.competitions
                                .firstWhere((c) => c.id == value)
                                .teams;
                            _selectedHomeTeamId = null;
                            _selectedAwayTeamId = null;
                          });
                        }
                      },
                      validator: (v) =>
                          v == null ? 'Please select a competition' : null,
                    ),
                    const SizedBox(height: 16),

                    // Team Selectors (appear after competition is selected)
                    if (_selectedCompetitionId != null) ...[
                      DropdownButtonFormField<int>(
                        value: _selectedHomeTeamId,
                        hint: const Text('Select Home Team *'),
                        items: _teamsInCompetition
                            .where((t) => t.id != _selectedAwayTeamId)
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedHomeTeamId = v),
                        validator: (v) =>
                            v == null ? 'Please select a home team' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedAwayTeamId,
                        hint: const Text('Select Away Team *'),
                        items: _teamsInCompetition
                            .where((t) => t.id != _selectedHomeTeamId)
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedAwayTeamId = v),
                        validator: (v) =>
                            v == null ? 'Please select an away team' : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- DATE & TIME CARD ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat.yMMMd().format(_gameDate)),
                        onPressed: () async {
                          final newDate = await showDatePicker(
                            context: context,
                            initialDate: _gameDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (newDate != null) {
                            setState(() => _gameDate = newDate);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(_gameTime.format(context)),
                        onPressed: () async {
                          final newTime = await showTimePicker(
                            context: context,
                            initialTime: _gameTime,
                          );
                          if (newTime != null) {
                            setState(() => _gameTime = newTime);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- SAVE BUTTON ---
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Schedule Game'),
            ),
          ],
        ),
      ),
    );
  }
}
