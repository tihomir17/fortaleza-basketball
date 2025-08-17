// lib/features/teams/presentation/screens/team_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'edit_team_screen.dart';
// We will create this file in the next step
// import '../../../../features/authentication/presentation/screens/edit_user_screen.dart';
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
  void initState() {
    super.initState();
    // Subscribe to the global refresh signal
    _refreshSignal.addListener(_refreshTeamDetails);
  }

  @override
  void dispose() {
    // Unsubscribe to prevent memory leaks
    _refreshSignal.removeListener(_refreshTeamDetails);
    super.dispose();
  }

  // When the signal is fired, re-fetch the data for this screen
  void _refreshTeamDetails() {
    final token = context.read<AuthCubit>().state.token;
    if (token != null && mounted) {
      context.read<TeamDetailCubit>().fetchTeamDetails(
        token: token,
        teamId: widget.teamId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              title: Text(titleText),
              actions: [
                if (state.status == TeamDetailStatus.success &&
                    state.team != null)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Team',
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EditTeamScreen(team: state.team!),
                        ),
                      );
                      if (result == true) {
                        sl<RefreshSignal>().notify();
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
                      onTap: () {
                        // TODO: Navigate to Edit Coach Screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Edit coach functionality coming soon!',
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Players',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Divider(),
                  for (final player in team.players)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColorLight,
                        child: Text(
                          player.jerseyNumber?.toString() ?? '#',
                          style: TextStyle(
                            color: Theme.of(context).primaryColorDark,
                          ),
                        ),
                      ),
                      title: Text(player.displayName),
                      subtitle: const Text('Player'),
                      onTap: () {
                        // TODO: Navigate to Edit Player Screen
                        // Example (once EditUserScreen is created):
                        // Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditUserScreen(user: player)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Edit player functionality coming soon!',
                            ),
                          ),
                        );
                      },
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
                context.go(
                  '/teams/${widget.teamId}/plays',
                  extra: state.team!.name,
                );
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
