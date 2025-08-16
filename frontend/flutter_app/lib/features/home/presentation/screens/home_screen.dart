// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/presentation/screens/create_team_screen.dart';
import '../../../teams/presentation/cubit/team_cubit.dart';
import '../../../teams/presentation/cubit/team_state.dart';

import 'package:flutter_app/core/navigation/refresh_signal.dart'; // Import the signal
import 'package:flutter_app/main.dart'; // Import GetIt

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Get the global refresh signal instance
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();

  @override
  void initState() {
    super.initState();
    // Subscribe to the signal. When it fires, call _refreshTeams.
    _refreshSignal.addListener(_refreshTeams);
  }

  @override
  void dispose() {
    // Unsubscribe to prevent memory leaks
    _refreshSignal.removeListener(_refreshTeams);
    super.dispose();
  }

  void _refreshTeams() {
    final token = context.read<AuthCubit>().state.token;
    if (token != null && mounted) {
      context.read<TeamCubit>().fetchTeams(token: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      body: BlocBuilder<TeamCubit, TeamState>(
        builder: (context, state) {
          if (state.status == TeamStatus.loading ||
              state.status == TeamStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TeamStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }
          if (state.status == TeamStatus.success && state.teams.isEmpty) {
            return const Center(
              child: Text('You are not a member of any teams.'),
            );
          }

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
                  // Navigate using go_router. No need to await.
                  context.go('/teams/${team.id}');
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateTeamScreen()));
          // After creating, we don't need a result, just notify.
          _refreshSignal.notify();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
