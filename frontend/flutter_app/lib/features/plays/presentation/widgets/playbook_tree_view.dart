// lib/features/plays/presentation/widgets/playbook_tree_view.dart

import 'package:flutter/material.dart';
import '../../data/models/play_definition_model.dart';

class PlaybookTreeView extends StatelessWidget {
  final List<PlayDefinition> allPlays;
  final ValueChanged<PlayDefinition>
  onPlaySelected; // Callback for when a play is tapped

  const PlaybookTreeView({
    super.key,
    required this.allPlays,
    required this.onPlaySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Separate plays into categories
    final offensivePlays = allPlays
        .where((p) => p.playType == 'OFFENSIVE')
        .toList();
    final defensivePlays = allPlays
        .where((p) => p.playType == 'DEFENSIVE')
        .toList();

    return ListView(
      children: [
        if (offensivePlays.isNotEmpty)
          _PlayCategoryList(
            title: 'Offensive Plays',
            allPlays: offensivePlays,
            onPlaySelected: onPlaySelected,
          ),
        if (defensivePlays.isNotEmpty)
          _PlayCategoryList(
            title: 'Defensive Plays',
            allPlays: defensivePlays,
            onPlaySelected: onPlaySelected,
          ),
      ],
    );
  }
}

class _PlayCategoryList extends StatelessWidget {
  final String title;
  final List<PlayDefinition> allPlays;
  final ValueChanged<PlayDefinition> onPlaySelected;

  const _PlayCategoryList({
    required this.title,
    required this.allPlays,
    required this.onPlaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final rootPlays = allPlays.where((p) => p.parentId == null).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 20),
          ...rootPlays.map((rootPlay) => _buildPlayTree(rootPlay, allPlays)),
        ],
      ),
    );
  }

  Widget _buildPlayTree(PlayDefinition parent, List<PlayDefinition> allPlays) {
    final children = allPlays.where((p) => p.parentId == parent.id).toList();

    // Leaf node (a final, selectable play)
    if (children.isEmpty) {
      return ListTile(
        leading: const Opacity(
          opacity: 0.5,
          child: Icon(Icons.subdirectory_arrow_right, size: 20),
        ),
        title: Text(parent.name),
        dense: true,
        onTap: () => onPlaySelected(parent), // Use the callback
      );
    }

    // Branch node (an expandable category)
    return ExpansionTile(
      leading: const Icon(Icons.account_tree_outlined),
      title: Text(
        parent.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: children
          .map(
            (child) => Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _buildPlayTree(child, allPlays),
            ),
          )
          .toList(),
    );
  }
}
