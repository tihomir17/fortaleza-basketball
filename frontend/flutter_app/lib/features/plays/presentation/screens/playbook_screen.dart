// lib/features/plays/presentation/screens/playbook_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/plays/presentation/screens/create_play_screen.dart';
import '../../data/models/play_definition_model.dart';
import '../cubit/playbook_cubit.dart';
import '../cubit/playbook_state.dart';

class PlaybookScreen extends StatelessWidget {
  final String teamName;
  final int teamId;

  const PlaybookScreen({
    super.key,
    required this.teamName,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$teamName Playbook')),
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
            return const Center(child: Text('This team has no plays yet.'));
          }

          final offensivePlays = state.plays
              .where((p) => p.playType == 'OFFENSIVE')
              .toList();
          final defensivePlays = state.plays
              .where((p) => p.playType == 'DEFENSIVE')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (offensivePlays.isNotEmpty)
                _PlayCategory(title: 'Offensive Plays', plays: offensivePlays),

              if (offensivePlays.isNotEmpty && defensivePlays.isNotEmpty)
                const SizedBox(height: 24),

              if (defensivePlays.isNotEmpty)
                _PlayCategory(title: 'Defensive Plays', plays: defensivePlays),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final token = context.read<AuthCubit>().state.token;

          // This call now matches the constructor defined in Step 1
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => CreatePlayScreen(teamId: teamId)),
          );

          if (result == true && context.mounted && token != null) {
            context.read<PlaybookCubit>().fetchPlays(
              token: token,
              teamId: teamId,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PlayCategory extends StatelessWidget {
  final String title;
  final List<PlayDefinition> plays;

  const _PlayCategory({required this.title, required this.plays});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const Divider(),
        ...plays.map(
          (play) => ListTile(
            title: Text(play.name),
            subtitle: Text(play.description ?? 'No description.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
