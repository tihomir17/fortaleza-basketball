// lib/features/possessions/presentation/screens/edit_possession_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fortaleza_basketball_analytics/core/navigation/refresh_signal.dart';
import 'package:fortaleza_basketball_analytics/main.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/games/data/models/game_model.dart';
import 'package:fortaleza_basketball_analytics/features/plays/data/models/play_definition_model.dart';
import 'package:fortaleza_basketball_analytics/features/plays/data/repositories/play_repository.dart';
import 'package:fortaleza_basketball_analytics/features/plays/presentation/widgets/playbook_tree_view.dart';
import '../../data/models/possession_model.dart';
import '../../data/repositories/possession_repository.dart';

class EditPossessionScreen extends StatefulWidget {
  final Possession possession;
  final Game game;
  const EditPossessionScreen({
    super.key,
    required this.possession,
    required this.game,
  });

  @override
  State<EditPossessionScreen> createState() => _EditPossessionScreenState();
}

class _EditPossessionScreenState extends State<EditPossessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startTimeController;
  late TextEditingController _durationController;
  late int _selectedQuarter;
  late String _selectedOutcome;
  late List<String> _actions;
  late bool _isOffensivePossession;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.possession;
    _startTimeController = TextEditingController(text: p.startTimeInGame);
    _durationController = TextEditingController(
      text: p.durationSeconds.toString(),
    );
    _selectedQuarter = p.quarter;
    _selectedOutcome = p.outcome;

    _isOffensivePossession = p.offensiveSequence.isNotEmpty;
    final sequenceString = _isOffensivePossession
        ? p.offensiveSequence
        : p.defensiveSequence;
    _actions = sequenceString.isNotEmpty ? sequenceString.split(' -> ') : [];
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _showAddActionDialog() {
    final teamForPlaybook = widget.possession.team?.team;
    if (teamForPlaybook == null) return;

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
                  teamId: teamForPlaybook.id,
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Authentication Error.')));
      setState(() => _isLoading = false);
      return;
    }

    final opponent = widget.game.homeTeam.id == widget.possession.team!.team.id
        ? widget.game.awayTeam
        : widget.game.homeTeam;
    if (opponent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Opponent could not be determined.'),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final sequence = _actions.join(' -> ');

    try {
      await sl<PossessionRepository>().updatePossession(
        token: token,
        possessionId: widget.possession.id,
        gameId: widget.game.id,
        teamId: widget.possession.team!.team.id,
        opponentId: opponent.id,
        startTime: _startTimeController.text,
        duration: int.tryParse(_durationController.text) ?? 0,
        quarter: _selectedQuarter,
        outcome: _selectedOutcome,
        offensiveSequence: _isOffensivePossession ? sequence : "",
        defensiveSequence: !_isOffensivePossession ? sequence : "",
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
      appBar: AppBar(title: const Text('Edit Possession')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- METADATA ---
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
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedQuarter,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1st Quarter')),
                DropdownMenuItem(value: 2, child: Text('2nd Quarter')),
                DropdownMenuItem(value: 3, child: Text('3rd Quarter')),
                DropdownMenuItem(value: 4, child: Text('4th Quarter')),
                DropdownMenuItem(value: 5, child: Text('Overtime')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedQuarter = v);
              },
              decoration: const InputDecoration(labelText: 'Quarter *'),
            ),
            const Divider(height: 32),

            // --- INTERACTIVE SEQUENCE BUILDER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sequence", style: Theme.of(context).textTheme.titleLarge),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Add Action"),
                  onPressed: _showAddActionDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _actions.isEmpty
                  ? const Text("No actions in sequence.")
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _actions.asMap().entries.map((entry) {
                        int idx = entry.key;
                        String action = entry.value;
                        return Chip(
                          label: Text("${idx + 1}. $action"),
                          onDeleted: () {
                            setState(() => _actions.removeAt(idx));
                          },
                        );
                      }).toList(),
                    ),
            ),
            const Divider(height: 32),

            // --- OUTCOME ---
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
            const SizedBox(height: 32),

            // --- SAVE BUTTON ---
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
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
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
