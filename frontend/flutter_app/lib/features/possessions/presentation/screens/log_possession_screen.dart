// lib/features/possessions/presentation/screens/log_possession_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fortaleza_basketball_analytics/core/navigation/refresh_signal.dart';
import 'package:fortaleza_basketball_analytics/features/games/data/models/game_model.dart';
import 'package:fortaleza_basketball_analytics/features/games/presentation/cubit/game_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/games/presentation/cubit/game_state.dart';
import 'package:fortaleza_basketball_analytics/features/plays/data/models/play_definition_model.dart';
import 'package:fortaleza_basketball_analytics/features/plays/data/repositories/play_repository.dart';
import 'package:fortaleza_basketball_analytics/features/plays/presentation/widgets/playbook_tree_view.dart';
import 'package:fortaleza_basketball_analytics/features/teams/data/models/team_model.dart';
import 'package:fortaleza_basketball_analytics/main.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/possession_repository.dart';

// Main widget responsible for safely loading the required data
class LogPossessionScreen extends StatelessWidget {
  const LogPossessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log New Possession')),
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          if (state.status == GameStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == GameStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? "Failed to load games."),
            );
          }
          if (state.filteredGames.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "No games found.\nPlease create a game before logging a possession.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // If games are loaded, build the actual logging UI
          return _LogPossessionView(games: state.filteredGames);
        },
      ),
    );
  }
}

// Private StatefulWidget to manage the complex form state
class _LogPossessionView extends StatefulWidget {
  final List<Game> games;
  const _LogPossessionView({required this.games});

  @override
  _LogPossessionViewState createState() => _LogPossessionViewState();
}

enum PossessionLogStep { selectGame, selectTeam, buildPossession }

enum PossessionBuildStep { logging, finished }

class _LogPossessionViewState extends State<_LogPossessionView> {
  PossessionLogStep _logStep = PossessionLogStep.selectGame;
  PossessionBuildStep _buildStep = PossessionBuildStep.logging;

  Game? _selectedGame;
  Team? _teamWithPossession;

  final List<String> _actions = [];
  bool _isOffensivePossession = true;

  int _selectedQuarter = 1;
  String? _selectedOutcome;
  final _startTimeController = TextEditingController();
  final _durationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _startTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _onGameSelected(Game game) {
    setState(() {
      _selectedGame = game;
      _logStep = PossessionLogStep.selectTeam;
    });
  }

  void _onTeamSelected(Team team, bool isOffensive) {
    setState(() {
      _teamWithPossession = team;
      _isOffensivePossession = isOffensive;
      _logStep = PossessionLogStep.buildPossession;
    });
  }

  void _endPossession() {
    setState(() => _buildStep = PossessionBuildStep.finished);
  }

  void _showAddActionDialog() {
    if (_teamWithPossession == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder:
            (BuildContext sheetContext, ScrollController scrollController) {
              final authState = context.read<AuthCubit>().state;
              if (authState.token == null) {
                return const Center(child: Text("Authentication Error."));
              }

              return FutureBuilder<List<PlayDefinition>>(
                future: sl<PlayRepository>().getPlaysForTeam(
                  token: authState.token!,
                  teamId: _teamWithPossession!.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No plays found for this team."),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Select an Action",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: PlaybookTreeView(
                          allPlays: snapshot.data!,
                          onPlaySelected: (play) {
                            setState(() => _actions.add(play.name));
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
      ),
    );
  }

  Future<void> _savePossession() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final token = context.read<AuthCubit>().state.token;
    if (token == null ||
        _selectedGame == null ||
        _teamWithPossession == null ||
        _selectedOutcome == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Missing required data.")),
        );
      }
      setState(() => _isLoading = false);
      return;
    }
    final opponent = _selectedGame!.homeTeam.id == _teamWithPossession!.id
        ? _selectedGame!.awayTeam
        : _selectedGame!.homeTeam;
    if (opponent == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Opponent could not be determined."),
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final sequence = _actions.join(' -> ');

    try {
      await sl<PossessionRepository>().createPossession(
        token: token,
        gameId: _selectedGame!.id,
        teamId: _teamWithPossession!.id,
        opponentId: opponent.id,
        startTime: _startTimeController.text,
        duration: int.tryParse(_durationController.text) ?? 0,
        quarter: _selectedQuarter,
        outcome: _selectedOutcome!,
        offensiveSequence: _isOffensivePossession ? sequence : '',
        defensiveSequence: !_isOffensivePossession ? sequence : '',
      );
      if (mounted) {
        sl<RefreshSignal>().notify();
        context.go('/games');
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
    switch (_logStep) {
      case PossessionLogStep.selectGame:
        return _buildGameSelection(widget.games);
      case PossessionLogStep.selectTeam:
        return _buildTeamSelection();
      case PossessionLogStep.buildPossession:
        return _buildPossessionForm();
    }
  }

  Widget _buildGameSelection(List<Game> games) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return Card(
          child: ListTile(
            title: Text('${game.homeTeam.name} vs ${game.awayTeam.name}'),
            subtitle: Text(
              'Date: ${game.gameDate != null ? DateFormat.yMMMd().format(game.gameDate) : "No date"}',
            ),
            onTap: () => _onGameSelected(game),
          ),
        );
      },
    );
  }

  Widget _buildTeamSelection() {
    if (_selectedGame == null) {
      return const Center(child: Text("Error: No game selected."));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Which team had this possession?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.sports_basketball_outlined),
              onPressed: () => _onTeamSelected(_selectedGame!.homeTeam, true),
              label: Text(_selectedGame!.homeTeam.name),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "vs",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.shield_outlined),
              onPressed: () => _onTeamSelected(_selectedGame!.awayTeam, false),
              label: Text(_selectedGame!.awayTeam.name),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPossessionForm() {
    final opponent = _selectedGame!.homeTeam.id == _teamWithPossession!.id
        ? _selectedGame!.awayTeam
        : _selectedGame!.homeTeam;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Metadata section
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: Text(
              _teamWithPossession!.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("vs ${opponent.name}"),
            dense: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time (MM:SS) *',
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (Secs) *',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedQuarter,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1Q')),
                    DropdownMenuItem(value: 2, child: Text('2Q')),
                    DropdownMenuItem(value: 3, child: Text('3Q')),
                    DropdownMenuItem(value: 4, child: Text('4Q')),
                    DropdownMenuItem(value: 5, child: Text('OT')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedQuarter = v);
                  },
                  decoration: const InputDecoration(labelText: 'Quarter *'),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          // Sequence builder
          Text("Sequence", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _actions.isEmpty ? "No actions added yet." : _actions.join(' ➡ '),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          if (_buildStep == PossessionBuildStep.logging)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Action"),
                  onPressed: _showAddActionDialog,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text("End Possession"),
                  onPressed: _endPossession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                  ),
                ),
              ],
            ),
          if (_buildStep == PossessionBuildStep.finished) ...[
            const Divider(height: 32),
            // Outcome section
            DropdownButtonFormField<String>(
              value: _selectedOutcome,
              items: const [
                DropdownMenuItem(
                  value: 'MADE_2PT',
                  child: Text('Made 2-Point Shot'),
                ),
                DropdownMenuItem(
                  value: 'MISSED_2PT',
                  child: Text('Missed 2-Point Shot'),
                ),
                DropdownMenuItem(
                  value: 'MADE_3PT',
                  child: Text('Made 3-Point Shot'),
                ),
                DropdownMenuItem(
                  value: 'MISSED_3PT',
                  child: Text('Missed 3-Point Shot'),
                ),
                DropdownMenuItem(
                  value: 'MADE_FT',
                  child: Text('Made Free Throw(s)'),
                ),
                DropdownMenuItem(
                  value: 'MISSED_FT',
                  child: Text('Missed Free Throw(s)'),
                ),
                DropdownMenuItem(
                  value: 'TO_TRAVEL',
                  child: Text('Turnover: Traveling'),
                ),
                DropdownMenuItem(
                  value: 'TO_OFFENSIVE_FOUL',
                  child: Text('Turnover: Offensive Foul'),
                ),
                DropdownMenuItem(
                  value: 'TO_OUT_OF_BOUNDS',
                  child: Text('Turnover: Out of Bounds'),
                ),
                DropdownMenuItem(
                  value: 'TO_SHOT_CLOCK',
                  child: Text('Turnover: Shot Clock'),
                ),
                DropdownMenuItem(
                  value: 'TO_8_SECONDS',
                  child: Text('Turnover: 8 Seconds'),
                ),
                DropdownMenuItem(
                  value: 'TO_3_SECONDS',
                  child: Text('Turnover: 3 Seconds'),
                ),
                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedOutcome = value);
              },
              decoration: const InputDecoration(
                labelText: 'Possession Outcome *',
              ),
              validator: (v) => v == null ? 'Please select an outcome' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePossession,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Save Possession"),
            ),
          ],
        ],
      ),
    );
  }
}
