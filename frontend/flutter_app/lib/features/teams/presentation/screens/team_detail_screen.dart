// lib/features/teams/presentation/screens/team_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'edit_team_screen.dart';
import '../cubit/team_detail_cubit.dart';
import '../cubit/team_detail_state.dart';

class TeamDetailScreen extends StatelessWidget {
  final int teamId;
  const TeamDetailScreen({super.key, required this.teamId});

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
  Widget build(BuildContext context) {
    return Scaffold(
      // THE ENTIRE APPBAR IS NOW WRAPPED IN THE BLOCBUILDER
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<TeamDetailCubit, TeamDetailState>(
          builder: (context, state) {
            // Determine the title based on the state
            final titleText =
                (state.status == TeamDetailStatus.success && state.team != null)
                ? state.team!.name
                : 'Team Details';

            return AppBar(
              title: Text(titleText),
              // The actions list is now correctly placed inside the AppBar
              actions: [
                // Only build the button if the team has loaded successfully
                if (state.status == TeamDetailStatus.success &&
                    state.team != null)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Team',
                    onPressed: () async {
                      // Navigate to the edit screen and wait for a result
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EditTeamScreen(team: state.team!),
                        ),
                      );

                      // If the result is true, a change was made, so refresh the data
                      if (result == true && context.mounted) {
                        final token = context.read<AuthCubit>().state.token;
                        if (token != null) {
                          context.read<TeamDetailCubit>().fetchTeamDetails(
                            token: token,
                            teamId: teamId,
                          );
                        }
                      }
                    },
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
                      title: Text(coach.displayName),
                      subtitle: Text(_formatCoachType(coach.coachType)),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Players',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Divider(),
                  for (final player in team.players)
                    ListTile(
                      title: Text(player.displayName),
                      subtitle: const Text('Player'),
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
                context.go('/teams/$teamId/plays', extra: state.team!.name);
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
