// lib/features/teams/presentation/screens/team_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/authentication/presentation/screens/edit_coach_screen.dart';
import 'package:flutter_app/features/authentication/presentation/screens/edit_user_screen.dart';
import 'package:flutter_app/features/teams/presentation/screens/manage_roster_screen.dart';
import 'edit_team_screen.dart';
import '../cubit/team_detail_cubit.dart';
import '../cubit/team_detail_state.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();

  @override
  void initState() {
    super.initState();
    _refreshSignal.addListener(_refreshTeamDetails);
  }

  @override
  void dispose() {
    _refreshSignal.removeListener(_refreshTeamDetails);
    super.dispose();
  }

  void _refreshTeamDetails() {
    final token = context.read<AuthCubit>().state.token;
    if (token != null && mounted) {
      context.read<TeamDetailCubit>().fetchTeamDetails(
        token: token,
        teamId: widget.teamId,
      );
    }
  }

  String _formatCoachType(String? coachType) {
    if (coachType == null || coachType == 'NONE') return 'Coach';
    return coachType
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              title: Text(titleText.toUpperCase()),
              actions: [
                if (state.status == TeamDetailStatus.success &&
                    state.team != null)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.people_alt_outlined),
                        tooltip: 'Manage Roster',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ManageRosterScreen(team: state.team!),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Team Name',
                        onPressed: () async {
                          await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => EditTeamScreen(team: state.team!),
                            ),
                          );
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
          if (state.status == TeamDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TeamDetailStatus.failure || state.team == null) {
            return Center(
              child: Text(state.errorMessage ?? 'Error loading team data.'),
            );
          }

          final team = state.team!;
          final sortedPlayers = List.of(team.players)
            ..sort((a, b) {
              final numA = a.jerseyNumber ?? 1000;
              final numB = b.jerseyNumber ?? 1000;
              if (numA == numB) return a.displayName.compareTo(b.displayName);
              return numA.compareTo(numB);
            });

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              // --- COACHES CARD ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                        child: Text(
                          "COACHING STAFF",
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const Divider(),
                      if (team.coaches.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No coaches assigned.')),
                        )
                      else
                        ...team.coaches.map(
                          (coach) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withAlpha(50),
                              child: Icon(
                                Icons.person_outline,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              coach.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(_formatCoachType(coach.coachType)),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditCoachScreen(coach: coach),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // --- PLAYERS CARD ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                        child: Text(
                          "PLAYERS",
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const Divider(),
                      if (sortedPlayers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No players assigned.')),
                        )
                      else
                        ...sortedPlayers.map(
                          (player) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.secondary
                                  .withOpacity(0.8),
                              child: Text(
                                player.jerseyNumber?.toString() ?? "#",
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              player.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text('Player'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditUserScreen(user: player),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
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
              label: const Text('PLAYBOOK'),
              icon: const Icon(Icons.menu_book),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
