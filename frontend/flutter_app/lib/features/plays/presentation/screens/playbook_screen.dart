// lib/features/plays/presentation/screens/playbook_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_state.dart';
import 'package:flutter_app/features/plays/presentation/cubit/create_play_cubit.dart';
import 'package:flutter_app/features/plays/presentation/screens/create_play_screen.dart';
import '../../../../features/teams/data/models/team_model.dart';
import '../cubit/playbook_cubit.dart';
import '../cubit/playbook_state.dart';

class PlaybookScreen extends StatelessWidget {
  // We pass the team in so we can display its name in the AppBar
  final Team team;
  const PlaybookScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    // Get the auth state to access the token
    final authState = context.watch<AuthCubit>().state;
    // Get the current user to check their role
    final user = authState.user;
    return Scaffold(
      appBar: AppBar(title: Text('${team.name} Playbook')),
      body: BlocBuilder<PlaybookCubit, PlaybookState>(
        builder: (context, state) {
          if (state.status == PlaybookStatus.loading ||
              state.status == PlaybookStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == PlaybookStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }
          if (state.status == PlaybookStatus.success && state.plays.isEmpty) {
            return const Center(
              child: Text('This team has no plays in its playbook.'),
            );
          }
          if (state.status == PlaybookStatus.success) {
            return ListView.builder(
              itemCount: state.plays.length,
              itemBuilder: (context, index) {
                final play = state.plays[index];
                return ListTile(
                  // Use an icon to quickly identify the play type
                  leading: Icon(
                    play.playType == 'OFFENSIVE'
                        ? Icons.sports_basketball
                        : Icons.shield,
                    color: play.playType == 'OFFENSIVE'
                        ? Colors.orange
                        : Colors.blue,
                  ),
                  title: Text(play.name),
                  subtitle: Text(play.description ?? 'No description.'),
                );
              },
            );
          }
          // Fallback case
          return const SizedBox.shrink();
        },
      ),
      // ADD THIS FLOATING ACTION BUTTON
      floatingActionButton:
          user?.role ==
              'COACH' // Only show the button if the user is a coach
          ? FloatingActionButton(
              onPressed: () async {
                if (authState.status == AuthStatus.authenticated) {
                  // Navigate to the create screen and wait for a result
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider(create: (_) => sl<CreatePlayCubit>()),
                          // Pass down the existing AuthCubit instance
                          BlocProvider.value(value: context.read<AuthCubit>()),
                        ],
                        child: CreatePlayScreen(team: team),
                      ),
                    ),
                  );

                  // If the result is true, it means a play was created successfully
                  if (result == true && context.mounted) {
                    // Refresh the playbook to show the new play
                    context.read<PlaybookCubit>().fetchPlays(
                      token: authState.token!,
                      teamId: team.id,
                    );
                  }
                }
              },
              child: const Icon(Icons.add),
            )
          : null, // Don't show the button if not a coach
    );
  }
}
