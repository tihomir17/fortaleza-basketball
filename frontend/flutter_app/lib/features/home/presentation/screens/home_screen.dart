// lib/features/home/presentation/screens/home_screen.dart

// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart'; // Import the AppBar
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/features/teams/presentation/screens/create_team_screen.dart';
import '../../../teams/presentation/cubit/team_cubit.dart';
import '../../../teams/presentation/cubit/team_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _refreshTeams(BuildContext context) {
    final token = context.read<AuthCubit>().state.token;
    if (token != null) {
      context.read<TeamCubit>().fetchTeams(token: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserProfileAppBar(
        title: 'MY TEAMS',
        onRefresh: () => _refreshTeams(context),
      ),
      body: BlocBuilder<TeamCubit, TeamState>(
        builder: (context, state) {
          if (state.status == TeamStatus.loading ||
              state.status == TeamStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TeamStatus.failure) {
            return _buildErrorState(context, state.errorMessage);
          }
          if (state.status == TeamStatus.success && state.teams.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshTeams(context),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: state.teams.length,
              itemBuilder: (context, index) {
                final team = state.teams[index];
                return TeamCard(
                  team: team,
                  onTap: () => context.go('/teams/${team.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Awaiting the result here is now less critical, but good practice
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateTeamScreen()));
          // Manually refresh after returning
          _refreshTeams(context);
        },
        tooltip: 'Create Team',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'No Teams Found',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the + button to create your first team.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              'An Error Occurred',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message ?? 'Could not load data.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TeamCard extends StatefulWidget {
  final Team team;
  final VoidCallback onTap;

  const TeamCard({super.key, required this.team, required this.onTap});

  @override
  _TeamCardState createState() => _TeamCardState();
}

class _TeamCardState extends State<TeamCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_animation),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withAlpha(220),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withAlpha(50),
                    child: Text(
                      widget.team.name.isNotEmpty
                          ? widget.team.name[0].toUpperCase()
                          : 'T',
                      style: TextStyle(
                        fontFamily: 'Anton',
                        color: theme.colorScheme.secondary,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.team.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Coaches: ${widget.team.coaches.length}, Players: ${widget.team.players.length}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: theme.dividerColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
