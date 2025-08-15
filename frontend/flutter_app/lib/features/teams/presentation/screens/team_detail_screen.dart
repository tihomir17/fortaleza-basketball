// lib/features/teams/presentation/screens/team_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/team_detail_cubit.dart';
import '../cubit/team_detail_state.dart';

class TeamDetailScreen extends StatelessWidget {
  const TeamDetailScreen({super.key});

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
      appBar: AppBar(
        // We'll set the title dynamically based on the state
        title: BlocBuilder<TeamDetailCubit, TeamDetailState>(
          builder: (context, state) {
            if (state.status == TeamDetailStatus.success &&
                state.team != null) {
              return Text(state.team!.name);
            }
            return const Text('Team Details');
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
                  // List the coaches
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
                  // List the players
                  for (final player in team.players)
                    ListTile(
                      title: Text(player.displayName),
                      subtitle: const Text('Player'),
                    ),
                ],
              ),
            );
          }
          // Fallback case
          return const Center(child: Text('No team data available.'));
        },
      ),
    );
  }
}
