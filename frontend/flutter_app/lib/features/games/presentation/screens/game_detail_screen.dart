// lib/features/games/presentation/screens/game_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/features/possessions/data/models/possession_model.dart';
import '../cubit/game_detail_cubit.dart';
import '../cubit/game_detail_state.dart';

class GameDetailScreen extends StatelessWidget {
  final int gameId;
  const GameDetailScreen({super.key, required this.gameId});

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

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              // Game Header Card
              Card(
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

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Logged Possessions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // You can add a "Log New" button here if you want
                  ],
                ),
              ),

              if (game.possessions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No possessions have been logged for this game yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                // Build the list of possessions using our custom card
                ...game.possessions.map(
                  (possession) => _PossessionCard(possession: possession),
                ),
            ],
          );
        },
      ),
    );
  }
}

// A new, dedicated widget for displaying a single possession
class _PossessionCard extends StatelessWidget {
  final Possession possession;
  const _PossessionCard({required this.possession});

  @override
  Widget build(BuildContext context) {
    // Determine which team is the opponent for this specific possession
    final theme = Theme.of(context);
    final game = context.read<GameDetailCubit>().state.game!;
    final opponent = (game.homeTeam.id == possession.team?.id)
        ? game.awayTeam
        : game.homeTeam;

    // Determine color and icon based on outcome
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
            possession.team!.name.isNotEmpty
                ? possession.team!.name[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(
          '${possession.team?.name} Possession',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Q${possession.quarter} at ${possession.startTimeInGame}',
        ),

        // A trailing widget that shows the outcome visually
        trailing: Chip(
          label: Text(
            _formatOutcome(possession.outcome),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: outcomeColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        children: [
          // This is the expanded content
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quarter: ${possession.quarter}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Duration: ${possession.durationSeconds}s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to make the outcome text more readable
  String _formatOutcome(String outcome) {
    return outcome.replaceAll('_', ' ').replaceFirst('TO ', 'Turnover: ');
  }
}
