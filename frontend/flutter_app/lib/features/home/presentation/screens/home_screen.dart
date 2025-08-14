// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
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
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          )
        ],
      ),
      body: BlocBuilder<TeamCubit, TeamState>(
        builder: (context, state) {
          // If loading, show a spinner
          if (state.status == TeamStatus.loading || state.status == TeamStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          // If failed, show an error message
          if (state.status == TeamStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }
          // If success but no teams, show a message
          if (state.status == TeamStatus.success && state.teams.isEmpty) {
            return const Center(child: Text('You are not a member of any teams.'));
          }
          // If success and there are teams, show them in a list
          return ListView.builder(
            itemCount: state.teams.length,
            itemBuilder: (context, index) {
              final team = state.teams[index];
              return ListTile(
                title: Text(team.name),
                subtitle: Text('Coaches: ${team.coaches.length}, Players: ${team.players.length}'),
              );
            },
          );
        },
      ),
    );
  }
}