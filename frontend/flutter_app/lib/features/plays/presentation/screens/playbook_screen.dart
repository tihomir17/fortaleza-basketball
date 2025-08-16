// lib/features/plays/presentation/screens/playbook_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/plays/presentation/screens/create_play_screen.dart';
import 'package:flutter_app/main.dart'; // For Service Locator (sl)
import '../../data/models/play_definition_model.dart';
import '../../data/repositories/play_repository.dart';
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
      appBar: AppBar(
        title: Text('$teamName Playbook'),
        elevation: 0,
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey[50],
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

          final allOffensivePlays = state.plays
              .where((p) => p.playType == 'OFFENSIVE')
              .toList();
          final allDefensivePlays = state.plays
              .where((p) => p.playType == 'DEFENSIVE')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              if (allOffensivePlays.isNotEmpty)
                _PlayCategoryCard(
                  title: 'Offensive Plays',
                  allPlays: allOffensivePlays,
                ),
              if (allDefensivePlays.isNotEmpty)
                _PlayCategoryCard(
                  title: 'Defensive Plays',
                  allPlays: allDefensivePlays,
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final token = context.read<AuthCubit>().state.token;
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

class _PlayCategoryCard extends StatelessWidget {
  final String title;
  final List<PlayDefinition> allPlays;

  const _PlayCategoryCard({required this.title, required this.allPlays});

  @override
  Widget build(BuildContext context) {
    final rootPlays = allPlays.where((p) => p.parentId == null).toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            ...rootPlays.map((rootPlay) => _buildPlayTree(rootPlay, allPlays)),
          ],
        ),
      ),
    );
  }

  /// This is a recursive function that builds a widget tree from a flat list of plays.
  Widget _buildPlayTree(PlayDefinition parent, List<PlayDefinition> allPlays) {
    final children = allPlays.where((p) => p.parentId == parent.id).toList();

    // BASE CASE: If there are no children, this is a "leaf" node.
    if (children.isEmpty) {
      return ListTile(
        leading: const Opacity(
          opacity: 0.5,
          child: Icon(Icons.subdirectory_arrow_right, size: 20),
        ),
        title: Text(parent.name),
        subtitle: parent.description != null && parent.description!.isNotEmpty
            ? Text(parent.description!)
            : null,
        trailing: _DeletePlayButton(play: parent),
        dense: true,
      );
    }

    // RECURSIVE STEP: If there are children, this is a category (a "branch").
    return ExpansionTile(
      leading: const Icon(Icons.account_tree_outlined),
      trailing: _DeletePlayButton(play: parent),
      title: Text(
        parent.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: children
          .map(
            (child) => Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
              ), // Indent children visually
              child: _buildPlayTree(child, allPlays),
            ),
          )
          .toList(),
    );
  }
}

// Helper widget for the delete button and its logic
class _DeletePlayButton extends StatelessWidget {
  final PlayDefinition play;
  const _DeletePlayButton({required this.play});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.delete_outline, color: Colors.red[700]),
      onPressed: () => _showDeleteConfirmation(context, play),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PlayDefinition play) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Play'),
          content: Text(
            'Are you sure you want to delete "${play.name}"? This action will also delete all its sub-plays and cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red[700])),
              onPressed: () async {
                final token = context.read<AuthCubit>().state.token;
                if (token == null) {
                  Navigator.of(dialogContext).pop();
                  return;
                }

                try {
                  await sl<PlayRepository>().deletePlay(
                    token: token,
                    playId: play.id,
                  );
                  Navigator.of(dialogContext).pop(); // Close the dialog

                  // Refresh the playbook by finding the cubit and calling fetchPlays
                  final teamId =
                      play.teamId; // We have the teamId on the play object
                  context.read<PlaybookCubit>().fetchPlays(
                    token: token,
                    teamId: teamId,
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting play: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
