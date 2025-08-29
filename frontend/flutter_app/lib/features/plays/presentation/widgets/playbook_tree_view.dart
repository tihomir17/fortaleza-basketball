// lib/features/plays/presentation/widgets/playbook_tree_view.dart

// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/plays/data/repositories/play_repository.dart';
import 'package:flutter_app/features/plays/presentation/screens/edit_play_screen.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/plays/presentation/cubit/play_category_cubit.dart';
import 'package:flutter_app/features/plays/presentation/cubit/play_category_state.dart';
import '../../data/models/play_category_model.dart';
import '../../data/models/play_definition_model.dart';

class PlaybookTreeView extends StatelessWidget {
  final List<PlayDefinition> allPlays;
  final ValueChanged<PlayDefinition> onPlaySelected;

  const PlaybookTreeView({
    super.key,
    required this.allPlays,
    required this.onPlaySelected,
  });

  @override
  Widget build(BuildContext context) {
    // We now get the categories from the globally provided cubit
    return BlocBuilder<PlayCategoryCubit, PlayCategoryState>(
      builder: (context, categoryState) {
        if (categoryState.status != PlayCategoryStatus.success) {
          return const Center(child: Text("Loading categories..."));
        }

        final allCategories = categoryState.categories;

        return ListView.builder(
          itemCount: allCategories.length,
          itemBuilder: (context, index) {
            final category = allCategories[index];
            // Filter the master list of plays to get only the ones for this category
            final playsInCategory = allPlays
                .where((p) => p.category?.id == category.id)
                .toList();

            // Don't build a section if there are no plays for this category
            if (playsInCategory.isEmpty) {
              return const SizedBox.shrink();
            }

            return _PlayCategoryList(
              title: category.name.toUpperCase(),
              allPlays: playsInCategory,
              onPlaySelected: onPlaySelected,
            );
          },
        );
      },
    );
  }
}

// This helper widget remains mostly the same, but it's simpler
class _PlayCategoryList extends StatelessWidget {
  final String title;
  final List<PlayDefinition> allPlays;
  final ValueChanged<PlayDefinition> onPlaySelected;

  const _PlayCategoryList({
    required this.title,
    required this.allPlays,
    required this.onPlaySelected,
  });

  void _navigateToEdit(BuildContext context, PlayDefinition play) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EditPlayScreen(play: play)));
    // After returning, fire a global refresh signal.
    // The PlaybookHubScreen and other screens can listen for this.
    sl<RefreshSignal>().notify();
  }

  void _showDeleteConfirmation(BuildContext context, PlayDefinition play) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Play'),
          content: Text(
            'Are you sure you want to delete "${play.name}"? This will also delete all its sub-plays.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () async {
                final token = context.read<AuthCubit>().state.token;
                if (token == null) return;
                try {
                  await sl<PlayRepository>().deletePlay(
                    token: token,
                    playId: play.id,
                  );
                  Navigator.of(dialogContext).pop();
                  sl<RefreshSignal>().notify();
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

  @override
  Widget build(BuildContext context) {
    // We only need to find the root plays for THIS category's list
    final rootPlays = allPlays.where((p) => p.parentId == null).toList();

    // The recursive _buildPlayTree method is correct and does not need to change.
    Widget buildPlayTree(PlayDefinition parent, List<PlayDefinition> allPlays) {
      final children = allPlays.where((p) => p.parentId == parent.id).toList();

      // Leaf node with Edit/Delete buttons
      if (children.isEmpty) {
        return ListTile(
          leading: const Opacity(
            opacity: 0.5,
            child: Icon(Icons.subdirectory_arrow_right, size: 20),
          ),
          title: Text(parent.name),
          dense: true,
          onTap: () => onPlaySelected(parent),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
                onPressed: () => _navigateToEdit(context, parent),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: 'Delete',
                onPressed: () => _showDeleteConfirmation(context, parent),
              ),
            ],
          ),
        );
      }

      // Branch node with Edit/Delete buttons
      return ExpansionTile(
        leading: const Icon(Icons.account_tree_outlined),
        title: Text(
          parent.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit',
              onPressed: () => _navigateToEdit(context, parent),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Delete',
              onPressed: () => _showDeleteConfirmation(context, parent),
            ),
          ],
        ),
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: buildPlayTree(child, allPlays),
              ),
            )
            .toList(),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            if (rootPlays.isEmpty)
              const Text('No plays in this category.')
            else
              ...rootPlays.map((rootPlay) => buildPlayTree(rootPlay, allPlays)),
          ],
        ),
      ),
    );
  }
}
