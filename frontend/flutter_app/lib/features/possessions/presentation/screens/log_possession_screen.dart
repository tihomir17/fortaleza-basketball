// lib/features/possessions/presentation/screens/log_possession_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/features/competitions/presentation/cubit/competition_cubit.dart';
import 'package:flutter_app/features/competitions/presentation/cubit/competition_state.dart';
import 'package:flutter_app/features/plays/data/models/play_definition_model.dart';
import 'package:flutter_app/features/plays/data/repositories/play_repository.dart';
import 'package:flutter_app/features/plays/presentation/widgets/playbook_tree_view.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/features/teams/presentation/screens/create_team_screen.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
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
  int? _selectedCompetitionId;
  List<Team> _teamsInSelectedCompetition = [];
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
      body: Stepper(
        // <-- USE A STEPPER WIDGET
        type: StepperType.vertical,
        currentStep: _currentStep.index, // Map our enum to the stepper's index
        onStepTapped: null, // Disable tapping on headers
        controlsBuilder: (context, details) {
          // Custom controls allow us to have our specific buttons
          if (_currentStep == PossessionStep.initial) {
            return _buildInitialStepControls();
          }
          if (_currentStep == PossessionStep.logging) {
            return _buildLoggingStepControls();
          }
          if (_currentStep == PossessionStep.finished) {
            return _buildFinishedStepControls();
          }
          return const SizedBox.shrink();
        },
        steps: [
          // STEP 1: INITIAL CHOICE
          Step(
            title: const Text('Possession Type'),
            content: const Text(
              'Select whether you are logging an offensive or defensive possession.',
            ),
            isActive: _currentStep.index >= 0,
            state: _currentStep.index > 0
                ? StepState.complete
                : StepState.indexed,
          ),
          // STEP 2: LOGGING ACTIONS
          Step(
            title: const Text('Build Sequence & Metadata'),
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildMetadataSection(),
                  const Divider(height: 32),
                  Text(
                    "Sequence",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Container(/* ... Sequence display container ... */),
                ],
              ),
            ),
            isActive: _currentStep.index >= 1,
            state: _currentStep.index > 1
                ? StepState.complete
                : StepState.indexed,
          ),
          // STEP 3: OUTCOME AND SAVE
          Step(
            title: const Text('Final Outcome'),
            content: _buildOutcomeSection(),
            isActive: _currentStep.index >= 2,
            state: _currentStep.index > 2
                ? StepState.complete
                : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return BlocBuilder<CompetitionCubit, CompetitionState>(
      builder: (context, competitionState) {
        if (competitionState.status == CompetitionStatus.loading) {
          return const Center(child: Text("Loading competitions..."));
        }
        if (competitionState.status == CompetitionStatus.failure) {
          return const Center(child: Text("Could not load competitions."));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Metadata", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Competition *'),
              hint: const Text('Select Competition'),
              value: _selectedCompetitionId,
              items: competitionState.competitions
                  .map(
                    (comp) => DropdownMenuItem(
                      value: comp.id,
                      child: Text(comp.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCompetitionId = value;
                    _teamsInSelectedCompetition = competitionState.competitions
                        .firstWhere((c) => c.id == value)
                        .teams;
                    _selectedOpponentId = null;
                  });
                }
              },
              validator: (v) =>
                  v == null ? 'Please select a competition' : null,
            ),
            const SizedBox(height: 16),
            if (_selectedCompetitionId != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedOpponentId,
                      items: _teamsInSelectedCompetition
                          .where((t) => t.id != widget.team.id)
                          .map(
                            (team) => DropdownMenuItem(
                              value: team.id,
                              child: Text(team.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedOpponentId = value),
                      decoration: const InputDecoration(
                        labelText: 'Opponent *',
                      ),
                      validator: (v) =>
                          v == null ? 'Please select an opponent' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add New Team to Competition',
                      onPressed: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const CreateTeamScreen(),
                          ),
                        );
                        if (result == true) {
                          sl<RefreshSignal>().notify();
                        }
                      },
                    ),
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

  Widget _buildInitialStepControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.sports_basketball_outlined),
            label: const Text("Log Offensive Possession"),
            onPressed: () => _startLogging(true),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.shield_outlined),
            label: const Text("Log Defensive Possession"),
            onPressed: () => _startLogging(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggingStepControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _showAddActionDialog,
            child: const Text("Add Action"),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _endPossession,
            child: const Text("End Possession"),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedStepControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePossession,
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text("Save Possession"),
      ),
    );
  }
}
