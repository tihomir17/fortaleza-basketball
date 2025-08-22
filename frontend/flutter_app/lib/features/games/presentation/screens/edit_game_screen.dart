// lib/features/games/presentation/screens/edit_game_screen.dart

// ignore_for_file: unused_import, unused_field, unused_element

import 'package:flutter/material.dart';
import 'package:flutter_app/features/competitions/presentation/cubit/competition_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/competitions/presentation/cubit/competition_cubit.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import '../../data/models/game_model.dart';
import '../../data/repositories/game_repository.dart';

class EditGameScreen extends StatefulWidget {
  final Game game;
  const EditGameScreen({super.key, required this.game});

  @override
  State<EditGameScreen> createState() => _EditGameScreenState();
}

class _EditGameScreenState extends State<EditGameScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _gameDate;
  late TimeOfDay _gameTime;
  late int _selectedCompetitionId;
  late int _selectedHomeTeamId;
  late int _selectedAwayTeamId;
  List<Team> _teamsInCompetition = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final g = widget.game;
    _gameDate = g.gameDate;
    _gameTime = TimeOfDay.fromDateTime(g.gameDate);
    _selectedCompetitionId = g.competitionId!;
    _selectedHomeTeamId = g.homeTeam.id;
    _selectedAwayTeamId = g.awayTeam.id;

    // Pre-load the teams for the game's competition
    final competitionState = context.read<CompetitionCubit>().state;
    _teamsInCompetition = competitionState.competitions
        .firstWhere((c) => c.id == _selectedCompetitionId)
        .teams;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      /* handle error */
      return;
    }

    try {
      final finalGameTime = DateTime(
        _gameDate.year,
        _gameDate.month,
        _gameDate.day,
        _gameTime.hour,
        _gameTime.minute,
      );
      // We will create this repository method next
      await sl<GameRepository>().updateGame(
        token: token,
        gameId: widget.game.id,
        competitionId: _selectedCompetitionId,
        homeTeamId: _selectedHomeTeamId,
        awayTeamId: _selectedAwayTeamId,
        gameDate: finalGameTime,
      );

      if (mounted) {
        sl<RefreshSignal>().notify();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We get the list of all competitions to populate the first dropdown.
    final competitionState = context.watch<CompetitionCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Game')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- COMPETITION SELECTOR ---
            DropdownButtonFormField<int>(
              value: _selectedCompetitionId,
              hint: const Text('Select Competition'),
              // We check if competitions are loaded before building the items
              items: competitionState.status == CompetitionStatus.success
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
                    // When the competition changes, update the list of available teams
                    _teamsInCompetition = competitionState.competitions
                        .firstWhere((c) => c.id == value)
                        .teams;
                    // Reset the team selections
                    _selectedHomeTeamId = 0;
                    _selectedAwayTeamId = 0;
                  });
                }
              },
              validator: (v) => v == null ? 'Competition is required' : null,
            ),
            const SizedBox(height: 16),

            // --- TEAM SELECTORS ---
            // These are only visible after a competition has been selected.
            if (_selectedCompetitionId != null) ...[
              DropdownButtonFormField<int>(
                value: _selectedHomeTeamId,
                hint: const Text('Select Home Team'),
                // Filter out the currently selected away team from the choices
                items: _teamsInCompetition
                    .where((t) => t.id != _selectedAwayTeamId)
                    .map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedHomeTeamId = v!),
                validator: (v) => v == null ? 'Home Team is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedAwayTeamId,
                hint: const Text('Select Away Team'),
                // Filter out the currently selected home team from the choices
                items: _teamsInCompetition
                    .where((t) => t.id != _selectedHomeTeamId)
                    .map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedAwayTeamId = v!),
                validator: (v) => v == null ? 'Away Team is required' : null,
              ),
            ],
            const SizedBox(height: 24),

            // --- DATE & TIME PICKERS ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat.yMMMd().format(_gameDate)),
                    onPressed: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: _gameDate,
                        firstDate: DateTime(
                          2020,
                        ), // Allow past dates for editing
                        lastDate: DateTime(2030),
                      );
                      if (newDate != null) setState(() => _gameDate = newDate);
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
                      if (newTime != null) setState(() => _gameTime = newTime);
                    },
                  ),
                ),
              ],
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
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
