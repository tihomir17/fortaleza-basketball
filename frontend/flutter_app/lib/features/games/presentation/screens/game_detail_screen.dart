// lib/features/games/presentation/screens/game_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/possessions/data/models/possession_model.dart';
import '../cubit/game_detail_cubit.dart';
import '../cubit/game_detail_state.dart';
import 'package:flutter_app/features/possessions/presentation/screens/edit_possession_screen.dart';

class GameDetailScreen extends StatefulWidget {
  final int gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  // The local state for the filter dropdown.
  int? _selectedQuarterFilter;
  // Get the global refresh signal instance
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();

  @override
  void initState() {
    super.initState();
    // Subscribe to the signal. When it fires, call _refreshGameDetails.
    _refreshSignal.addListener(_refreshGameDetails);
  }

  @override
  void dispose() {
    // Unsubscribe to prevent memory leaks
    _refreshSignal.removeListener(_refreshGameDetails);
    super.dispose();
  }

  // When the signal is fired, re-fetch the data for this screen
  void _refreshGameDetails() {
    final token = context.read<AuthCubit>().state.token;
    if (token != null && mounted) {
      context.read<GameDetailCubit>().fetchGameDetails(
        token: token,
        gameId: widget.gameId,
      );
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
                child: filteredPossessions.isEmpty
                    ? const Center(
                        child: Text('No possessions found for this period.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: filteredPossessions.length,
                        itemBuilder: (context, index) {
                          final possession = filteredPossessions[index];
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
  final Possession _possession;
  final Game _game;

  const _PossessionCard({required Possession possession, required Game game})
    : _game = game,
      _possession = possession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamWithBall = _possession.team;
    if (teamWithBall == null) {
      return const Card(
        child: ListTile(title: Text("Data Error: Missing team")),
      );
    }

    final opponent = (_game.homeTeam.id == teamWithBall.id)
        ? _game.awayTeam
        : _game.homeTeam;

    final bool wasTurnover = _possession.outcome.startsWith('TO_');
    final bool wasScore = _possession.outcome.startsWith('MADE_');
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
          'Q${_possession.quarter} at ${_possession.startTimeInGame}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Chip(
          label: Text(
            _formatOutcome(_possession.outcome),
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
                if (_possession.offensiveSequence.isNotEmpty) ...[
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
                      _possession.offensiveSequence,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_possession.defensiveSequence.isNotEmpty) ...[
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
                      _possession.defensiveSequence,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Duration: ${_possession.durationSeconds}s',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                onPressed: () {
                  // Navigate to the Log screen in EDIT mode
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditPossessionScreen(
                        possession: _possession,
                        game: _game,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatOutcome(String outcome) {
    return outcome.replaceAll('_', ' ').replaceFirst('TO ', 'TO: ');
  }
}
