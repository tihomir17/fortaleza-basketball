// lib/features/playbook/presentation/screens/playbook_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_state.dart';
import 'package:flutter_app/features/plays/presentation/cubit/playbook_cubit.dart';
import 'package:flutter_app/features/plays/presentation/cubit/playbook_state.dart';
import 'package:flutter_app/features/plays/presentation/widgets/playbook_tree_view.dart';
import 'package:flutter_app/main.dart'; // For GetIt

class PlaybookHubScreen extends StatefulWidget {
  const PlaybookHubScreen({super.key});

  @override
  State<PlaybookHubScreen> createState() => _PlaybookHubScreenState();
}

class _PlaybookHubScreenState extends State<PlaybookHubScreen> {
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();
  Team? _selectedTeam;

  @override
  void initState() {
    super.initState();
    // Subscribe to the signal
    _refreshSignal.addListener(_refreshPlays);
  }

  @override
  void dispose() {
    // Unsubscribe
    _refreshSignal.removeListener(_refreshPlays);
    super.dispose();
  }

  // This method will be called by the signal
  void _refreshPlays() {
    if (_selectedTeam != null && mounted) {
      final token = context.read<AuthCubit>().state.token;
      if (token != null) {
        context.read<PlaybookCubit>().fetchPlaysForTeam(
          token: token,
          teamId: _selectedTeam!.id,
        );
      }
    }
  }

  void _onTeamSelected(Team team) {
    setState(() => _selectedTeam = team);
    final token = context.read<AuthCubit>().state.token;
    if (token != null) {
      context.read<PlaybookCubit>().fetchPlaysForTeam(
        token: token,
        teamId: team.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We no longer need a BlocProvider here.
      body: BlocBuilder<TeamCubit, TeamState>(
        builder: (context, teamState) {
          if (teamState.status == TeamStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (teamState.teams.isEmpty) {
            return const Center(child: Text("You are not on any teams."));
          }

          // Auto-select if only one team
          if (_selectedTeam == null && teamState.teams.length == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onTeamSelected(teamState.teams.first);
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (_selectedTeam == null) {
            return _buildTeamSelection(context, teamState.teams);
          }

          // If a team IS selected, show the playbook UI
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<Team>(
                  value: _selectedTeam,
                  items: teamState.teams
                      .map(
                        (team) => DropdownMenuItem(
                          value: team,
                          child: Text(team.name),
                        ),
                      )
                      .toList(),
                  onChanged: (team) {
                    if (team != null) _onTeamSelected(team);
                  },
                  decoration: const InputDecoration(labelText: "Selected Team"),
                ),
              ),
              Expanded(
                child: BlocBuilder<PlaybookCubit, PlaybookState>(
                  builder: (context, playbookState) {
                    if (playbookState.status == PlaybookStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (playbookState.status == PlaybookStatus.failure) {
                      return Center(
                        child: Text(playbookState.errorMessage ?? 'Error'),
                      );
                    }
                    if (playbookState.plays.isEmpty) {
                      return const Center(
                        child: Text('This team has no plays yet.'),
                      );
                    }

                    return PlaybookTreeView(
                      allPlays: playbookState.plays,
                      onPlaySelected: (play) {
                        /* Handle play selection */
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamSelection(BuildContext context, List<Team> teams) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Select a Team',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Please choose a team to view their playbook.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ...teams.map(
          (team) => Card(
            child: ListTile(
              title: Text(
                team.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _onTeamSelected(team),
            ),
          ),
        ),
      ],
    );
  }
}
