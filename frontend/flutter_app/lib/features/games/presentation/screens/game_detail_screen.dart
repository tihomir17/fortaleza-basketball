// lib/features/games/presentation/screens/game_detail_screen.dart

import 'package:flutter_app/features/possessions/data/models/possession_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/game_detail_cubit.dart';
import '../cubit/game_detail_state.dart';

class GameDetailScreen extends StatelessWidget {
  final int gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Details')),
      body: BlocBuilder<GameDetailCubit, GameDetailState>(
        builder: (context, state) {
          if (state.status == GameDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == GameDetailStatus.failure || state.game == null) {
            return const Center(child: Text('Error loading game data.'));
          }

          final game = state.game!;

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              // Header Card
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
                        'Date: ${DateFormat.yMMMd().format(game.gameDate)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Logged Possessions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),

              if (game.possessions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No possessions have been logged for this game yet.',
                    ),
                  ),
                )
              else
                // Build the list of possessions
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

// A new widget for displaying a single possession
class _PossessionCard extends StatelessWidget {
  final Possession possession;
  const _PossessionCard({required this.possession});

  @override
  Widget build(BuildContext context) {
    // Determine the opponent for this specific possession
    final game = context.read<GameDetailCubit>().state.game!;
    final opponent = game.homeTeam.id == possession.team.id
        ? game.awayTeam
        : game.homeTeam;

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(child: Text(possession.team.name[0])),
        title: Text('${possession.team.name} Possession'),
        subtitle: Text(
          'Outcome: ${possession.outcome.replaceAll('_', ' ').toLowerCase()}',
        ),
        trailing: Text(possession.startTimeInGame),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (possession.offensiveSequence.isNotEmpty) ...[
                  Text(
                    'Offensive Sequence:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(possession.offensiveSequence),
                  const SizedBox(height: 12),
                ],
                if (possession.defensiveSequence.isNotEmpty) ...[
                  Text(
                    'Defensive Sequence (${opponent.name}):',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(possession.defensiveSequence),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
