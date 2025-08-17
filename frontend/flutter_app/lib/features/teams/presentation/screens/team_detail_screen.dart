// lib/features/teams/presentation/screens/team_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'edit_team_screen.dart';

import '../cubit/team_detail_cubit.dart';
import '../cubit/team_detail_state.dart';

import 'manage_roster_screen.dart';
import 'package:flutter_app/features/authentication/presentation/screens/edit_user_screen.dart';
import 'package:flutter_app/features/authentication/presentation/screens/edit_coach_screen.dart';
import 'package:flutter_app/features/possessions/presentation/screens/log_possession_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();

  String _formatCoachType(String? coachType) {
    if (coachType == null || coachType == 'NONE') {
      return 'Coach'; // Default fallback
    }
    // Replace underscores with spaces and capitalize the first letter of each word.
    return coachType
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    // Subscribe to the global refresh signal
    _refreshSignal.addListener(_refreshTeamDetails);
  }

  @override
  void dispose() {
    // Unsubscribe to prevent memory leaks
    _refreshSignal.removeListener(_refreshTeamDetails);
    super.dispose();
  }

  // When the signal is fired, re-fetch the data for this screen
  void _refreshTeamDetails() {
    final token = context.read<AuthCubit>().state.token;
    if (token != null && mounted) {
      context.read<TeamDetailCubit>().fetchTeamDetails(
        token: token,
        teamId: widget.teamId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<TeamDetailCubit, TeamDetailState>(
          builder: (context, state) {
            final titleText =
                (state.status == TeamDetailStatus.success && state.team != null)
                ? state.team!.name
                : 'Team Details';
            return AppBar(
              title: Text(titleText),
              actions: [
                // Only show buttons if the team has loaded successfully
                if (state.status == TeamDetailStatus.success &&
                    state.team != null)
                  IconButton(
                    icon: const Icon(Icons.add_chart),
                    tooltip: 'Log Possession',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            // We find the TeamCubit that already exists in the current context...
                            value: context.read<TeamCubit>(),
                            // ...and provide that SAME instance to the new screen.
                            child: LogPossessionScreen(team: state.team!),
                          ),
                        ),
                      );
                    },
                  ),
                Row(
                  children: [
                    // BUTTON 1: MANAGE ROSTER
                    IconButton(
                      icon: const Icon(Icons.people_alt_outlined),
                      tooltip: 'Manage Roster',
                      onPressed: () {
                        // Navigate directly to the roster screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ManageRosterScreen(team: state.team!),
                          ),
                        );
                      },
                    ),
                    // BUTTON 2: EDIT TEAM NAME
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Team Name',
                      onPressed: () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => EditTeamScreen(team: state.team!),
                          ),
                        );
                        // The refresh signal will handle updates
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: BlocBuilder<TeamDetailCubit, TeamDetailState>(
        builder: (context, state) {
          if (state.status == TeamDetailStatus.loading ||
              state.status == TeamDetailStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TeamDetailStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }
          if (state.status == TeamDetailStatus.success && state.team != null) {
            final team = state.team!;

            final sortedPlayers = List.of(team.players);
            sortedPlayers.sort((a, b) {
              // Handle cases where numbers might be null
              final numA =
                  a.jerseyNumber ?? 1000; // Treat nulls as a large number
              final numB = b.jerseyNumber ?? 1000;
              return numA.compareTo(numB); // Sort in ascending order
            });
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Text(
                    'Coaches',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Divider(),
                  for (final coach in team.coaches)
                    ListTile(
                      leading: const CircleAvatar(
                        // Give coaches a distinct icon
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.person_outline, color: Colors.white),
                      ),
                      title: Text(coach.displayName),
                      subtitle: Text(
                        _formatCoachType(coach.coachType),
                      ), // We will create this helper
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditCoachScreen(coach: coach),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Players',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Divider(),
                  for (final player in sortedPlayers)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColorLight,
                        child: Text(
                          player.jerseyNumber?.toString() ?? '#',
                          style: TextStyle(
                            color: Theme.of(context).primaryColorDark,
                          ),
                        ),
                      ),
                      title: Text(player.displayName),
                      subtitle: const Text('Player'),
                      onTap: () {
                        // Navigate to Edit Player Screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditUserScreen(user: player),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          }
          return const Center(child: Text('No team data available.'));
        },
      ),
      floatingActionButton: BlocBuilder<TeamDetailCubit, TeamDetailState>(
        builder: (context, state) {
          if (state.status == TeamDetailStatus.success && state.team != null) {
            return FloatingActionButton.extended(
              onPressed: () {
                context.go(
                  '/teams/${widget.teamId}/plays',
                  extra: state.team!.name,
                );
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('Playbook'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
