// lib/features/games/presentation/screens/game_detail_screen.dart

// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_app/features/possessions/presentation/screens/live_tracking_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/possessions/data/models/possession_model.dart';
import 'package:flutter_app/features/possessions/data/repositories/possession_repository.dart';
import 'package:flutter_app/features/possessions/presentation/screens/edit_possession_screen.dart';
import 'package:flutter_app/core/logging/file_logger.dart';
import '../cubit/game_detail_cubit.dart';
import '../cubit/game_detail_state.dart';
import '../../data/repositories/game_repository.dart';

class GameDetailScreen extends StatefulWidget {
  final int gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  int? _selectedQuarterFilter;
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();
  bool _isLoadingMorePossessions = false;

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
        loadPossessions: true, // Load possessions for detail view
      );
    }
  }

  Future<void> _loadPossessionsFromDatabase() async {
    final token = context.read<AuthCubit>().state.token;
    if (token == null) return;
    
    setState(() => _isLoadingMorePossessions = true);
    
    try {
      // Load all possessions for this game from the database
      final possessionsData = await sl<GameRepository>().getGamePossessions(
        token: token,
        gameId: widget.gameId,
        page: 1,
        pageSize: 1000, // Load a large number to get all possessions
      );
      
      final allPossessions = (possessionsData['results'] as List)
          .map((json) => Possession.fromJson(json))
          .toList();
      
      // Update the game with all loaded possessions
      final game = context.read<GameDetailCubit>().state.game;
      if (game != null) {
        game.possessions.clear(); // Clear existing possessions
        game.possessions.addAll(allPossessions); // Add all loaded possessions
        
        // Update the cubit state
        context.read<GameDetailCubit>().emit(
          context.read<GameDetailCubit>().state.copyWith(
            game: game,
            filteredPossessions: game.possessions,
          ),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded ${allPossessions.length} possessions from database'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load possessions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMorePossessions = false);
      }
    }
  }

  Future<void> _loadMorePossessions() async {
    if (_isLoadingMorePossessions) return;
    
    final token = context.read<AuthCubit>().state.token;
    if (token == null) return;
    
    setState(() => _isLoadingMorePossessions = true);
    
    try {
      final game = context.read<GameDetailCubit>().state.game;
      if (game != null) {
        final currentCount = game.possessions.length;
        final nextPage = (currentCount ~/ 50) + 1;
        
        final possessionsData = await sl<GameRepository>().getGamePossessions(
          token: token,
          gameId: widget.gameId,
          page: nextPage,
          pageSize: 50,
        );
        
        final newPossessions = (possessionsData['results'] as List)
            .map((json) => Possession.fromJson(json))
            .toList();
        
        // Add new possessions to the game
        game.possessions.addAll(newPossessions);
        
        // Update the cubit state
        context.read<GameDetailCubit>().emit(
          context.read<GameDetailCubit>().state.copyWith(
            game: game,
            filteredPossessions: game.possessions,
          ),
        );
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more possessions: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMorePossessions = false);
      }
    }
  }

  int _parseTimeToSeconds(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return 0;
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return (minutes * 60) + seconds;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Analysis'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.analytics_outlined,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                // Get the user's team ID from the game
                final game = context.read<GameDetailCubit>().state.game;
                if (game != null) {
                  final userTeams = context.read<TeamCubit>().state.teams;
                  final userTeamInGame = userTeams.firstWhere(
                    (t) => t.id == game.homeTeam.id || t.id == game.awayTeam.id,
                    orElse: () => game.homeTeam,
                  );
                  context.go('/games/${game.id}/post-game-report?teamId=${userTeamInGame.id}');
                }
              },
              tooltip: 'Post Game Report',
            ),
          ),
                     Padding(
             padding: const EdgeInsets.only(
               right: 8.0,
             ), // Add some space from the edge
             child: Center(
               // Use Center to vertically align the button
               child: BlocBuilder<GameDetailCubit, GameDetailState>(
                 builder: (context, state) {
                   final game = state.game;
                   final hasPossessions = game?.possessions.isNotEmpty ?? false;
                   final isLoading = _isLoadingMorePossessions;
                   
                   return TextButton.icon(
                     onPressed: isLoading ? null : _loadPossessionsFromDatabase,
                     icon: Icon(
                       isLoading ? Icons.hourglass_empty : Icons.download,
                       size: 18,
                     ),
                     label: Text(
                       isLoading ? 'Loading...' : (hasPossessions ? 'Reload' : 'Load Possessions'),
                     ),
                     style: TextButton.styleFrom(
                       // Use different colors based on state
                       foregroundColor: Colors.white,
                       backgroundColor: isLoading 
                           ? Colors.grey 
                           : (hasPossessions ? Colors.orange : Colors.green),
                       // Add a subtle border
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(20),
                       ),
                     ),
                   );
                 },
               ),
             ),
           ),
          Padding(
            padding: const EdgeInsets.only(
              right: 8.0,
            ), // Add some space from the edge
            child: Center(
              // Use Center to vertically align the button
              child: TextButton.icon(
                onPressed: () {
                  // The router will get the ID from the URL.
                  context.go('/games/${widget.gameId}/track');
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Possession'),
                style: TextButton.styleFrom(
                  // Use the theme's accent color for high visibility
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueGrey,
                  // Add a subtle border
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

          final sortedPossessions = List.of(filteredPossessions);
          sortedPossessions.sort((a, b) {
            int quarterComparison = a.quarter.compareTo(b.quarter);
            if (quarterComparison != 0) return quarterComparison;
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
                    DropdownMenuItem(value: 5, child: Text('Overtime')),
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.list_alt_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Possessions Logged',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedQuarterFilter == null
                                    ? 'Tap the "Log Possession" button on the Games screen to get started.'
                                    : 'No possessions found for this period.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
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
                          // Load More button
                          if (game.possessions.length >= 50) // Only show if we have loaded at least 50
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: _isLoadingMorePossessions ? null : _loadMorePossessions,
                                child: _isLoadingMorePossessions
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          SizedBox(width: 8),
                                          Text('Loading...'),
                                        ],
                                      )
                                    : const Text('Load More Possessions'),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PossessionCard extends StatefulWidget {
  final Possession possession;
  final Game game;
  const _PossessionCard({required this.possession, required this.game});

  @override
  State<_PossessionCard> createState() => _PossessionCardState();
}

class _PossessionCardState extends State<_PossessionCard> {

  String _formatOutcome(String outcome) {
    return outcome.replaceAll('_', ' ').replaceFirst('TO ', 'TO: ');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final possession = widget.possession;
    final game = widget.game;
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
        : (wasTurnover ? theme.colorScheme.error : const Color.fromARGB(255, 173, 97, 97));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 1,
      clipBehavior: Clip
          .antiAlias, // Ensures the background color respects the border radius
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigoAccent,
          child: Text(
            teamWithBall.name.isNotEmpty
                ? teamWithBall.name[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: Colors.white,
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

        // --- REDESIGNED TRAILING WIDGET ---
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: outcomeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _formatOutcome(possession.outcome),
            style: TextStyle(
              color: outcomeColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),

        // --- END OF REDESIGN ---
        onExpansionChanged: (bool expanded) {
        },
        children: [
          // --- STYLED DETAILS SECTION ---
          Container(
            color: Colors.black.withOpacity(0.03),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (possession.offensiveSequence.isNotEmpty) ...[
                  Text(
                    'Offensive Sequence:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    possession.offensiveSequence,
                    style: const TextStyle(fontFamily: 'monospace'),
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
                  Text(
                    possession.defensiveSequence,
                    style: const TextStyle(fontFamily: 'monospace'),
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

          // --- END OF STYLING ---
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
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: theme.colorScheme.error),
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
}
