// lib/features/games/presentation/screens/game_detail_screen.dart

// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/possessions/data/models/possession_model.dart';
import 'package:flutter_app/features/possessions/data/repositories/possession_repository.dart';
import 'package:flutter_app/features/possessions/presentation/screens/edit_possession_screen.dart';
import '../cubit/game_detail_cubit.dart';
import '../cubit/game_detail_state.dart';

class GameDetailScreen extends StatefulWidget {
  final int gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  int? _selectedQuarterFilter;
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();

  @override
  void initState() {
    super.initState();
    _refreshSignal.addListener(_refreshGameDetails);
  }

  @override
  void dispose() {
    _refreshSignal.removeListener(_refreshGameDetails);
    super.dispose();
  }

  void _refreshGameDetails() {
    final token = context.read<AuthCubit>().state.token;
    if (token != null && mounted) {
      context.read<GameDetailCubit>().fetchGameDetails(
        token: token,
        gameId: widget.gameId,
      );
    }
  }

  // Helper function to parse "MM:SS" time strings into a comparable integer.
  int _parseTimeToSeconds(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return 0;
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return (minutes * 60) + seconds;
    } catch (e) {
      return 0; // Return 0 if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Analysis')),
      body: BlocBuilder<GameDetailCubit, GameDetailState>(
        builder: (context, state) {
          if (state.status == GameDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == GameDetailStatus.failure || state.game == null) {
            return Center(
              child: Text(state.errorMessage ?? 'Error loading game data.'),
            );
          }

          final game = state.game!;

          final List<Possession> filteredPossessions;
          if (_selectedQuarterFilter == null) {
            filteredPossessions = game.possessions;
          } else {
            filteredPossessions = game.possessions
                .where((p) => p.quarter == _selectedQuarterFilter)
                .toList();
          }

          // Create a new sorted list from the filtered list
          final sortedPossessions = List.of(filteredPossessions);
          sortedPossessions.sort((a, b) {
            // Primary sort: by Quarter (ascending)
            int quarterComparison = a.quarter.compareTo(b.quarter);
            if (quarterComparison != 0) {
              return quarterComparison;
            }
            // Secondary sort: by Start Time (descending, high to low)
            int timeA = _parseTimeToSeconds(a.startTimeInGame);
            int timeB = _parseTimeToSeconds(b.startTimeInGame);
            return timeB.compareTo(timeA);
          });

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '${game.homeTeam.name} vs ${game.awayTeam.name}',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        game.gameDate != null
                            ? DateFormat.yMMMd().format(game.gameDate)
                            : "Date not set",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: DropdownButtonFormField<int?>(
                  value: _selectedQuarterFilter,
                  hint: const Text('Filter by Period...'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Full Game')),
                    DropdownMenuItem(value: 1, child: Text('1st Quarter')),
                    DropdownMenuItem(value: 2, child: Text('2nd Quarter')),
                    DropdownMenuItem(value: 3, child: Text('3rd Quarter')),
                    DropdownMenuItem(value: 4, child: Text('4th Quarter')),
                    DropdownMenuItem(value: 5, child: Text('Overtime 1')),
                    DropdownMenuItem(value: 6, child: Text('Overtime 2')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedQuarterFilter = value);
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  'Logged Possessions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(indent: 16, endIndent: 16),

              Expanded(
                child: sortedPossessions.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'No possessions found for this period.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: sortedPossessions.length,
                        itemBuilder: (context, index) {
                          final possession = sortedPossessions[index];
                          return _PossessionCard(
                            possession: possession,
                            game: game,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PossessionCard extends StatelessWidget {
  final Possession possession;
  final Game game;

  const _PossessionCard({required this.possession, required this.game});

  String _formatOutcome(String outcome) {
    return outcome.replaceAll('_', ' ').replaceFirst('TO ', 'TO: ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamWithBall = possession.team;
    if (teamWithBall == null) {
      return const Card(
        child: ListTile(title: Text("Data Error: Missing team")),
      );
    }

    final opponent = (game.homeTeam.id == teamWithBall.id)
        ? game.awayTeam
        : game.homeTeam;

    final bool wasTurnover = possession.outcome.startsWith('TO_');
    final bool wasScore = possession.outcome.startsWith('MADE_');
    final Color outcomeColor = wasScore
        ? Colors.green.shade700
        : (wasTurnover ? Colors.red.shade700 : Colors.grey.shade600);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withAlpha(50),
          child: Text(
            teamWithBall.name.isNotEmpty
                ? teamWithBall.name[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Possession for ${teamWithBall.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Q${possession.quarter} at ${possession.startTimeInGame}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Chip(
          label: Text(
            _formatOutcome(possession.outcome),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          backgroundColor: outcomeColor,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ).copyWith(top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(),
                if (possession.offensiveSequence.isNotEmpty) ...[
                  Text(
                    'Offensive Sequence:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      possession.offensiveSequence,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (possession.defensiveSequence.isNotEmpty) ...[
                  Text(
                    'Defensive Sequence (${opponent.name}):',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      possession.defensiveSequence,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Duration: ${possession.durationSeconds}s',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditPossessionScreen(
                          possession: possession,
                          game: game,
                        ),
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onPressed: () => _showDeleteConfirmation(context, possession),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Possession possession) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Possession'),
          content: Text(
            'Are you sure you want to delete this possession from Q${possession.quarter} at ${possession.startTimeInGame}? This action cannot be undone.',
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
                  await sl<PossessionRepository>().deletePossession(
                    token: token,
                    possessionId: possession.id,
                  );
                  Navigator.of(dialogContext).pop();
                  sl<RefreshSignal>().notify();
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting possession: $e')),
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
