// lib/features/possessions/presentation/screens/log_possession_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/features/plays/data/models/play_definition_model.dart';
import 'package:flutter_app/features/plays/data/repositories/play_repository.dart';
import 'package:flutter_app/features/plays/presentation/widgets/playbook_tree_view.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/features/teams/presentation/screens/create_team_screen.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import '../../data/repositories/possession_repository.dart';

enum PossessionStep { initial, logging, finished }

class LogPossessionScreen extends StatefulWidget {
  final Team team;
  const LogPossessionScreen({super.key, required this.team});

  @override
  State<LogPossessionScreen> createState() => _LogPossessionScreenState();
}

class _LogPossessionScreenState extends State<LogPossessionScreen> {
  PossessionStep _currentStep = PossessionStep.initial;
  bool _isOffensivePossession = true;
  final List<String> _actions = [];

  // Form State
  int? _selectedOpponentId;
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

  void _startLogging(bool isOffensive) {
    setState(() {
      _isOffensivePossession = isOffensive;
      _currentStep = PossessionStep.logging;
    });
  }

  void _showAddActionDialog() {
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
                teamId: widget.team.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No plays found or error loading playbook."),
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

  void _endPossession() {
    setState(() {
      _currentStep = PossessionStep.finished;
    });
  }

  Future<void> _savePossession() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    final sequence = _actions.join(' -> ');

    try {
      await sl<PossessionRepository>().createPossession(
        token: token,
        teamId: widget.team.id,
        opponentId: _selectedOpponentId,
        startTime: _startTimeController.text,
        duration: int.tryParse(_durationController.text) ?? 0,
        quarter: _selectedQuarter,
        outcome: _selectedOutcome!,
        offensiveSequence: _isOffensivePossession ? sequence : '',
        defensiveSequence: !_isOffensivePossession ? sequence : '',
      );
      if (mounted) {
        sl<RefreshSignal>().notify();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Log New Possession')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_currentStep == PossessionStep.initial) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.sports_basketball_outlined),
              label: const Text("Log Offensive Possession"),
              onPressed: () => _startLogging(true),
              style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.shield_outlined),
              label: const Text("Log Defensive Possession"),
              onPressed: () => _startLogging(false),
              style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMetadataSection(),
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
          if (_currentStep == PossessionStep.logging)
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
          if (_currentStep == PossessionStep.finished) ...[
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

  Widget _buildMetadataSection() {
    // We now wrap the whole section in a BlocBuilder that listens to the TeamCubit
    return BlocBuilder<TeamCubit, TeamState>(
      builder: (context, teamState) {
        // Handle loading and error states for the team list
        if (teamState.status == TeamStatus.loading) {
          return const Center(child: Text("Loading teams..."));
        }
        if (teamState.status == TeamStatus.failure) {
          return const Center(child: Text("Could not load teams."));
        }

        // Once the teams are loaded, we can build the form
        final potentialOpponents = teamState.teams
            .where((t) => t.id != widget.team.id)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Metadata", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedOpponentId,
                    // The items list is now guaranteed to be populated
                    items: potentialOpponents
                        .map(
                          (team) => DropdownMenuItem(
                            value: team.id,
                            child: Text(team.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedOpponentId = value),
                    decoration: const InputDecoration(labelText: 'Opponent *'),
                    validator: (v) =>
                        v == null ? 'Please select an opponent' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add New Opponent',
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const CreateTeamScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                    if (result == true) {
                      sl<RefreshSignal>().notify();
                    }
                  },
                ),
              ],
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
      },
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
}
