// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Import the go_router package
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/presentation/screens/create_team_screen.dart';

import '../../../teams/presentation/cubit/team_cubit.dart';
import '../../../teams/presentation/cubit/team_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Call the logout method from the AuthCubit.
              // The GoRouter redirect logic will automatically handle navigation.
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
      body: BlocBuilder<TeamCubit, TeamState>(
        builder: (context, state) {
          // If loading, show a spinner
          if (state.status == TeamStatus.loading ||
              state.status == TeamStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          // If failed, show an error message
          if (state.status == TeamStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }
          // If success but no teams, show a message
          if (state.status == TeamStatus.success && state.teams.isEmpty) {
            return const Center(
              child: Text('You are not a member of any teams.'),
            );
          }
          // If success and there are teams, show them in a list
          return ListView.builder(
            itemCount: state.teams.length,
            itemBuilder: (context, index) {
              final team = state.teams[index];
              return ListTile(
                title: Text(team.name),
                subtitle: Text(
                  'Coaches: ${team.coaches.length}, Players: ${team.players.length}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Use go_router for navigation, passing the team's ID in the URL.
                  // This will match the '/teams/:teamId' route we defined.
                  context.go('/teams/${team.id}');
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to the create screen and wait for a result.
          // We use MaterialPageRoute here because this isn't part of our main GoRouter flow.
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const CreateTeamScreen(),
              fullscreenDialog: true, // Presents the screen as a modal popup
            ),
          );

          // If the result is true, a new team was created, so refresh the list.
          if (result == true && context.mounted) {
            final token = context.read<AuthCubit>().state.token;
            if (token != null) {
              context.read<TeamCubit>().fetchTeams(token: token);
            }
          }
        },
        tooltip: 'Create Team',
        child: const Icon(Icons.add),
      ),
    );
  }
}
