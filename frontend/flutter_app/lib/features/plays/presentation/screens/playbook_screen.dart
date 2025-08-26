// lib/features/plays/presentation/screens/playbook_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/plays/presentation/screens/create_play_screen.dart';
import 'package:flutter_app/features/plays/presentation/screens/edit_play_screen.dart';
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
    // ... (This build method is correct and does not need changes)
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
              .where((p) => p.playType == 'OFFENSE')
              .toList();
          final allDefensivePlays = state.plays
              .where((p) => p.playType == 'DEFENSE')
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

  // A single, reusable navigation helper method for this widget
  void _navigateToEdit(BuildContext context, PlayDefinition play) async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => EditPlayScreen(play: play)));
    if (result == true && context.mounted) {
      final token = context.read<AuthCubit>().state.token;
      if (token != null) {
        context.read<PlaybookCubit>().fetchPlays(
          token: token,
          teamId: play.teamId,
        );
      }
    }
  }

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
            // We now pass 'context' to the recursive tree builder
            ...rootPlays.map(
              (rootPlay) => _buildPlayTree(context, rootPlay, allPlays),
            ),
          ],
        ),
      ),
    );
  }

  // This function now accepts the BuildContext to pass it down the tree
  Widget _buildPlayTree(
    BuildContext context,
    PlayDefinition parent,
    List<PlayDefinition> allPlays,
  ) {
    final children = allPlays.where((p) => p.parentId == parent.id).toList();

    if (children.isEmpty) {
      // BASE CASE: Leaf node
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
        onTap: () => _navigateToEdit(
          context,
          parent,
        ), // It can call the class-level helper
      );
    }

    // RECURSIVE STEP: Branch node
    return ExpansionTile(
      leading: const Icon(Icons.account_tree_outlined),
      title: Text(
        parent.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      // Pass the context to the action button builder
      trailing: _buildActionButtons(context, parent),
      children: children
          .map(
            (child) => Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _buildPlayTree(
                context,
                child,
                allPlays,
              ), // Pass context in recursion
            ),
          )
          .toList(),
    );
  }

  // This helper now accepts the BuildContext as a parameter
  Widget _buildActionButtons(BuildContext context, PlayDefinition play) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
          tooltip: 'Edit "${play.name}"',
          onPressed: () => _navigateToEdit(
            context,
            play,
          ), // It can call the class-level helper
        ),
        _DeletePlayButton(play: play),
      ],
    );
  }
}

class _DeletePlayButton extends StatelessWidget {
  // ... (This widget is correct and does not need changes)
  final PlayDefinition play;
  const _DeletePlayButton({required this.play});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.delete_outline, color: Colors.red[700]),
      tooltip: 'Delete "${play.name}"',
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
                  Navigator.of(dialogContext).pop();
                  final teamId = play.teamId;
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
