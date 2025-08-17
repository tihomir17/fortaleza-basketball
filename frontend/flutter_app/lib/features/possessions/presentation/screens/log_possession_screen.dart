// lib/features/possessions/presentation/screens/log_possession_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date formatting

import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_cubit.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_state.dart';
import 'package:flutter_app/features/plays/data/models/play_definition_model.dart';
import 'package:flutter_app/features/plays/data/repositories/play_repository.dart';
import 'package:flutter_app/features/plays/presentation/widgets/playbook_tree_view.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/possession_repository.dart';

enum PossessionLogStep { selectGame, selectTeam, buildPossession }

enum PossessionBuildStep { logging, finished }

class LogPossessionScreen extends StatefulWidget {
  const LogPossessionScreen({super.key});

  @override
  State<LogPossessionScreen> createState() => _LogPossessionScreenState();
}

class _LogPossessionScreenState extends State<LogPossessionScreen> {
  PossessionLogStep _logStep = PossessionLogStep.selectGame;
  PossessionBuildStep _buildStep = PossessionBuildStep.logging;

  // State for selected items
  Game? _selectedGame;
  Team? _teamWithPossession;

  // State for the possession being built
  List<String> _actions = [];
  bool _isOffensivePossession = true;

  // Form Controllers and State
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

  Future<void> _savePossession() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final token = context.read<AuthCubit>().state.token;
    if (token == null ||
        _selectedGame == null ||
        _teamWithPossession == null ||
        _selectedOutcome == null) {
      setState(() => _isLoading = false);
      return;
    }

    final sequence = _actions.join(' -> ');
    final opponent = _selectedGame!.homeTeam.id == _teamWithPossession!.id
        ? _selectedGame!.awayTeam
        : _selectedGame!.homeTeam;
    try {
      await sl<PossessionRepository>().createPossession(
        token: token,
        gameId: _selectedGame!.id,
        teamId: _teamWithPossession!.id,
        startTime: _startTimeController.text,
        duration: int.tryParse(_durationController.text) ?? 0,
        quarter: _selectedQuarter,
        outcome: _selectedOutcome!,
        offensiveSequence: _isOffensivePossession ? sequence : '',
        defensiveSequence: !_isOffensivePossession ? sequence : '',
        opponentId: opponent.id,
      );
      if (mounted) {
        sl<RefreshSignal>().notify(); // Notify other screens if needed
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getAppBarTitle())),
      body: _buildBody(),
    );
  }

  String _getAppBarTitle() {
    switch (_logStep) {
      case PossessionLogStep.selectGame:
        return 'Select a Game';
      case PossessionLogStep.selectTeam:
        return 'Select Team with Possession';
      case PossessionLogStep.buildPossession:
        return 'Log Possession';
    }
  }

  Widget _buildBody() {
    switch (_logStep) {
      case PossessionLogStep.selectGame:
        return _buildGameSelection();
      case PossessionLogStep.selectTeam:
        return _buildTeamSelection();
      case PossessionLogStep.buildPossession:
        return _buildPossessionForm();
    }
  }

  Widget _buildGameSelection() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        if (state.status == GameStatus.loading)
          return const Center(child: CircularProgressIndicator());
        if (state.status == GameStatus.failure)
          return Center(
            child: Text(state.errorMessage ?? "Failed to load games."),
          );
        if (state.games.isEmpty)
          return const Center(
            child: Text("No games found. Please create one first."),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: state.games.length,
          itemBuilder: (context, index) {
            final game = state.games[index];
            return Card(
              child: ListTile(
                title: Text(
                  '${game.homeTeam.name} vs ${game.awayTeam.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Date: ${DateFormat.yMMMd().format(game.gameDate)}',
                ),
                onTap: () => _onGameSelected(game),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeamSelection() {
    if (_selectedGame == null)
      return const Center(child: Text("Error: No game selected."));

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
          _buildMetadataSection(opponent),
          const Divider(height: 32),
          Text("Sequence", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
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
            _buildOutcomeSection(),
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

  Widget _buildMetadataSection(Team opponent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Metadata", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
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
      ],
    );
  }

  Widget _buildOutcomeSection() {
    return DropdownButtonFormField<String>(
      value: _selectedOutcome,
      items: const [
        DropdownMenuItem(value: 'MADE_2PT', child: Text('Made 2-Point Shot')),
        DropdownMenuItem(
          value: 'MISSED_2PT',
          child: Text('Missed 2-Point Shot'),
        ),
        DropdownMenuItem(value: 'MADE_3PT', child: Text('Made 3-Point Shot')),
        DropdownMenuItem(
          value: 'MISSED_3PT',
          child: Text('Missed 3-Point Shot'),
        ),
        DropdownMenuItem(value: 'MADE_FT', child: Text('Made Free Throw(s)')),
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
      decoration: const InputDecoration(labelText: 'Possession Outcome *'),
      validator: (v) => v == null ? 'Please select an outcome' : null,
    );
  }

  void _showAddActionDialog() {
    // We need the team that has possession to fetch its playbook
    if (_teamWithPossession == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            final authState = context.read<AuthCubit>().state;
            if (authState.token == null) {
              return const Center(child: Text("Authentication Error."));
            }
            return FutureBuilder<List<PlayDefinition>>(
              future: sl<PlayRepository>().getPlaysForTeam(
                token: authState.token!,
                teamId: _teamWithPossession!.id, // Use the correct team's ID
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
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
