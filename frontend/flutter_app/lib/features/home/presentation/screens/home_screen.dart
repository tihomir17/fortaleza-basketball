// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/main.dart';

// imports for the new screen and its dependencies
import '../../../authentication/presentation/cubit/auth_state.dart';
import '../../../teams/presentation/cubit/team_detail_cubit.dart';
import '../../../teams/presentation/screens/team_detail_screen.dart';

import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../../teams/presentation/cubit/team_cubit.dart';
import '../../../teams/presentation/cubit/team_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current authentication state, which contains our token
    final authState = context.watch<AuthCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
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
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ), // <-- A nice visual cue
                onTap: () {
                  if (authState.status == AuthStatus.authenticated &&
                      authState.token != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          // Use our service locator to create a fresh instance of TeamDetailCubit
                          create: (_) => sl<TeamDetailCubit>()
                            // Immediately fetch the details for the tapped team
                            ..fetchTeamDetails(
                              token: authState.token!,
                              teamId: team.id,
                            ),
                          child: const TeamDetailScreen(),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
