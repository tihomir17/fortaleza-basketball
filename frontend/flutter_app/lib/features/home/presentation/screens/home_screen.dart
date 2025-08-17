// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/presentation/screens/create_team_screen.dart';
import '../../../teams/presentation/cubit/team_cubit.dart';
import '../../../teams/presentation/cubit/team_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();

  @override
  void initState() {
    super.initState();
    _refreshSignal.addListener(_refreshTeams);
  }

  @override
  void dispose() {
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
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Toggle Theme',
            onPressed: () {
              // Call the toggle method on our ThemeCubit
              context.read<ThemeCubit>().toggleTheme();
            },
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
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'You are not a member of any teams yet. Tap the + button to create one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // Use a ListView with Cards for a cleaner look
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: state.teams.length,
            itemBuilder: (context, index) {
              final team = state.teams[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    team.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Coaches: ${team.coaches.length}, Players: ${team.players.length}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    context.go('/teams/${team.id}');
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateTeamScreen(),
              fullscreenDialog: true,
            ),
          );
          _refreshSignal.notify();
        },
        tooltip: 'Create Team',
        child: const Icon(Icons.add),
      ),
    );
  }
}
