// lib/features/playbook/presentation/screens/playbook_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_state.dart';

class PlaybookHubScreen extends StatelessWidget {
  const PlaybookHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserProfileAppBar(title: 'PLAYBOOK'),
      body: BlocBuilder<TeamCubit, TeamState>(
        builder: (context, state) {
          if (state.status == TeamStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TeamStatus.failure || state.teams.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'You must be a member of a team to view a playbook.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // If the user is only on ONE team, navigate them directly for a better UX.
          if (state.teams.length == 1) {
            final team = state.teams.first;
            // Use a post-frame callback to navigate safely after the build is complete.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/teams/${team.id}/plays', extra: team.name);
              }
            });
            // Show a loading indicator while the redirect happens.
            return const Center(child: CircularProgressIndicator());
          }

          // If the user is on MULTIPLE teams, show the selection list.
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
              ...state.teams.map(
                (team) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                      ),
                    ),
                    title: Text(
                      team.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // THIS IS THE FIX:
                    // Use the player and coach count, which the Team object has.
                    subtitle: Text(
                      '${team.players.length} Players, ${team.coaches.length} Coaches',
                    ),

                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to the specific playbook for the selected team
                      context.go('/teams/${team.id}/plays', extra: team.name);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
