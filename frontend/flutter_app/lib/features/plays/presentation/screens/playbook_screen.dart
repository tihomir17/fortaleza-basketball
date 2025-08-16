// lib/features/plays/presentation/screens/playbook_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/teams/data/models/team_model.dart';
import '../cubit/playbook_cubit.dart';
import '../cubit/playbook_state.dart';

class PlaybookScreen extends StatelessWidget {
  // We pass the team in so we can display its name in the AppBar
  final Team team;
  const PlaybookScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${team.name} Playbook'),
      ),
      body: BlocBuilder<PlaybookCubit, PlaybookState>(
        builder: (context, state) {
          if (state.status == PlaybookStatus.loading || state.status == PlaybookStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == PlaybookStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }
          if (state.status == PlaybookStatus.success && state.plays.isEmpty) {
            return const Center(child: Text('This team has no plays in its playbook.'));
          }
          if (state.status == PlaybookStatus.success) {
            return ListView.builder(
              itemCount: state.plays.length,
              itemBuilder: (context, index) {
                final play = state.plays[index];
                return ListTile(
                  // Use an icon to quickly identify the play type
                  leading: Icon(
                    play.playType == 'OFFENSIVE' ? Icons.sports_basketball : Icons.shield,
                    color: play.playType == 'OFFENSIVE' ? Colors.orange : Colors.blue,
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
    );
  }
}