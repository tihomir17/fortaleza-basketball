// lib/features/games/presentation/screens/game_detail_screen.dart

// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/features/possessions/presentation/screens/live_tracking_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/games/data/models/game_roster_model.dart';
import 'package:flutter_app/features/possessions/data/models/possession_model.dart';
import 'package:flutter_app/features/possessions/data/repositories/possession_repository.dart';
import 'package:flutter_app/features/possessions/presentation/screens/edit_possession_screen.dart';
import 'package:flutter_app/core/logging/file_logger.dart';
import '../cubit/game_detail_cubit.dart';
import '../cubit/game_detail_state.dart';
import '../../data/repositories/game_repository.dart';
import 'roster_management_screen.dart';
import 'starting_five_screen.dart';

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
  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _refreshSubscription = _refreshSignal.stream.listen((_) => _refreshGameDetails());
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  void _refreshGameDetails() {
    print('DEBUG: _refreshGameDetails - starting refresh for game ${widget.gameId}');
    final token = context.read<AuthCubit>().state.token;
    if (token != null && mounted) {
      print('DEBUG: _refreshGameDetails - clearing cache and fetching fresh data');
      // Clear the cache to ensure fresh data is loaded
      context.read<GameDetailCubit>().clearGameCache(widget.gameId);
      context.read<GameDetailCubit>().fetchGameDetails(
        token: token,
        gameId: widget.gameId,
        loadPossessions: true, // Load possessions for detail view
      );
      print('DEBUG: _refreshGameDetails - fetchGameDetails called');
    } else {
      print('DEBUG: _refreshGameDetails - token is null or widget not mounted');
    }
  }

  // Helper methods for game setup flow
  bool _hasRosters(Game? game) {
    if (game == null) {
      print('DEBUG: _hasRosters - game is null');
      return false;
    }
    final hasHome = game.homeTeamRoster != null;
    final hasAway = game.awayTeamRoster != null;
    print('DEBUG: _hasRosters - home: $hasHome, away: $hasAway');
    return hasHome && hasAway;
  }

  bool _hasHomeRoster(Game? game) {
    if (game == null) {
      print('DEBUG: _hasHomeRoster - game is null');
      return false;
    }
    final hasHome = game.homeTeamRoster != null;
    print('DEBUG: _hasHomeRoster - result: $hasHome');
    if (game.homeTeamRoster != null) {
      print('DEBUG: _hasHomeRoster - home roster players: ${game.homeTeamRoster!.players.length}');
    }
    return hasHome;
  }

  bool _hasAwayRoster(Game? game) {
    if (game == null) {
      print('DEBUG: _hasAwayRoster - game is null');
      return false;
    }
    final hasAway = game.awayTeamRoster != null;
    print('DEBUG: _hasAwayRoster - result: $hasAway');
    return hasAway;
  }

  bool _hasStartingFives(Game? game) {
    if (!_hasRosters(game)) {
      print('DEBUG: _hasStartingFives - no rosters, returning false');
      return false;
    }
    
    // Check if both rosters have exactly 5 starting five players
    final homeStartingFiveComplete = game!.homeTeamRoster!.startingFive.length == 5;
    final awayStartingFiveComplete = game.awayTeamRoster!.startingFive.length == 5;
    
    print('DEBUG: _hasStartingFives - home starting five: ${game.homeTeamRoster!.startingFive.length}/5, away starting five: ${game.awayTeamRoster!.startingFive.length}/5');
    print('DEBUG: _hasStartingFives - home complete: $homeStartingFiveComplete, away complete: $awayStartingFiveComplete');
    
    return homeStartingFiveComplete && awayStartingFiveComplete;
  }

  bool _canAddPossessions(Game? game) {
    if (game == null) {
      print('DEBUG: _canAddPossessions - game is null');
      return false;
    }
    
    // Must have both rosters AND both starting fives complete
    final hasBothRosters = game.homeTeamRoster != null && game.awayTeamRoster != null;
    if (!hasBothRosters) {
      print('DEBUG: _canAddPossessions - missing rosters, returning false');
      return false;
    }
    
    final homeStartingFiveComplete = game.homeTeamRoster!.startingFive.length == 5;
    final awayStartingFiveComplete = game.awayTeamRoster!.startingFive.length == 5;
    
    final canAdd = homeStartingFiveComplete && awayStartingFiveComplete;
    print('DEBUG: _canAddPossessions - home starting five: ${game.homeTeamRoster!.startingFive.length}/5, away starting five: ${game.awayTeamRoster!.startingFive.length}/5');
    print('DEBUG: _canAddPossessions - can add possessions: $canAdd');
    
    return canAdd;
  }

  // Navigation methods
  Future<void> _navigateToRosterManagement(Team team) async {
    print('DEBUG: _navigateToRosterManagement - starting for team: ${team.name}');
    final game = context.read<GameDetailCubit>().state.game;
    if (game == null) {
      print('DEBUG: _navigateToRosterManagement - game is null, returning');
      return;
    }

    print('DEBUG: _navigateToRosterManagement - navigating to roster management for ${team.name}');
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RosterManagementScreen(
          game: game,
          team: team,
        ),
      ),
    );

    print('DEBUG: _navigateToRosterManagement - returned with result: $result');
    if (result == true && mounted) {
      print('DEBUG: _navigateToRosterManagement - roster created successfully, refreshing game details');
      // Add a small delay to ensure backend has processed the roster creation
      await Future.delayed(const Duration(milliseconds: 500));
      _refreshGameDetails();
    } else {
      print('DEBUG: _navigateToRosterManagement - roster creation cancelled or failed');
    }
  }

  Future<void> _navigateToStartingFive(Team team, GameRoster roster) async {
    print('DEBUG: _navigateToStartingFive - starting for team: ${team.name}');
    final game = context.read<GameDetailCubit>().state.game;
    if (game == null) {
      print('DEBUG: _navigateToStartingFive - game is null, returning');
      return;
    }

    print('DEBUG: _navigateToStartingFive - navigating to starting five for ${team.name}');
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StartingFiveScreen(
          game: game,
          team: team,
          rosterPlayers: roster.players,
        ),
      ),
    );

    print('DEBUG: _navigateToStartingFive - returned with result: $result');
    if (result == true && mounted) {
      print('DEBUG: _navigateToStartingFive - starting five updated successfully, refreshing game details');
      // Add a small delay to ensure backend has processed the starting five update
      await Future.delayed(const Duration(milliseconds: 500));
      _refreshGameDetails();
    } else {
      print('DEBUG: _navigateToStartingFive - starting five update cancelled or failed');
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

  Widget _buildGameSetupSection(Game game) {
    final hasRosters = _hasRosters(game);
    final hasHomeRoster = _hasHomeRoster(game);
    final hasAwayRoster = _hasAwayRoster(game);
    final hasStartingFives = _hasStartingFives(game);
    final canAddPossessions = _canAddPossessions(game);

    print('DEBUG: _buildGameSetupSection - hasRosters: $hasRosters, hasHomeRoster: $hasHomeRoster, hasAwayRoster: $hasAwayRoster, hasStartingFives: $hasStartingFives, canAddPossessions: $canAddPossessions');
    print('DEBUG: _buildGameSetupSection - game.homeTeamRoster: ${game.homeTeamRoster}');
    print('DEBUG: _buildGameSetupSection - game.awayTeamRoster: ${game.awayTeamRoster}');

    // Don't show setup section if everything is complete
    if (canAddPossessions) {
      print('DEBUG: _buildGameSetupSection - setup complete, hiding section');
      return const SizedBox.shrink();
    }

    // Log which buttons will be shown
    if (!hasHomeRoster) {
      print('DEBUG: _buildGameSetupSection - showing home roster button');
    } else if (!hasAwayRoster) {
      print('DEBUG: _buildGameSetupSection - showing away roster button');
    } else if (!hasStartingFives) {
      print('DEBUG: _buildGameSetupSection - showing starting five buttons');
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game Setup',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Roster Status Display
            _buildRosterStatusDisplay(game),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Step 1: Create home roster first
                if (!hasHomeRoster) ...[
                  ElevatedButton.icon(
                    onPressed: () => _navigateToRosterManagement(game.homeTeam),
                    icon: const Icon(Icons.people, size: 18),
                    label: Text('${game.homeTeam.name} Roster'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else if (!hasAwayRoster) ...[
                  // Step 2: Create away roster after home roster is done
                  ElevatedButton.icon(
                    onPressed: () => _navigateToRosterManagement(game.awayTeam),
                    icon: const Icon(Icons.people, size: 18),
                    label: Text('${game.awayTeam.name} Roster'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else if (!hasStartingFives) ...[
                  // Step 3: Select starting fives for both teams after both rosters are done
                  if (game.homeTeamRoster!.startingFive.length != 5) ...[
                    ElevatedButton.icon(
                      onPressed: () => _navigateToStartingFive(game.homeTeam, game.homeTeamRoster!),
                      icon: const Icon(Icons.star, size: 18),
                      label: Text('${game.homeTeam.name} Starting Five'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  if (game.awayTeamRoster!.startingFive.length != 5) ...[
                    ElevatedButton.icon(
                      onPressed: () => _navigateToStartingFive(game.awayTeam, game.awayTeamRoster!),
                      icon: const Icon(Icons.star, size: 18),
                      label: Text('${game.awayTeam.name} Starting Five'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 8),
                                  Text(
                        _getSetupStatusText(game),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Both teams need rosters with minimum 10 players and complete starting fives before logging possessions.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterStatusDisplay(Game game) {
    final hasHomeRoster = _hasHomeRoster(game);
    final hasAwayRoster = _hasAwayRoster(game);
    final hasStartingFives = _hasStartingFives(game);
    
    print('DEBUG: _buildRosterStatusDisplay - hasHomeRoster: $hasHomeRoster, hasAwayRoster: $hasAwayRoster, hasStartingFives: $hasStartingFives');
    if (game.homeTeamRoster != null) {
      print('DEBUG: _buildRosterStatusDisplay - home roster players: ${game.homeTeamRoster!.players.length}, starting five: ${game.homeTeamRoster!.startingFive.length}');
    }
    if (game.awayTeamRoster != null) {
      print('DEBUG: _buildRosterStatusDisplay - away roster players: ${game.awayTeamRoster!.players.length}, starting five: ${game.awayTeamRoster!.startingFive.length}');
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Roster Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTeamRosterStatus(
                  team: game.homeTeam,
                  hasRoster: hasHomeRoster,
                  roster: game.homeTeamRoster,
                  isStartingFiveComplete: hasHomeRoster && game.homeTeamRoster!.startingFive.length == 5,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTeamRosterStatus(
                  team: game.awayTeam,
                  hasRoster: hasAwayRoster,
                  roster: game.awayTeamRoster,
                  isStartingFiveComplete: hasAwayRoster && game.awayTeamRoster!.startingFive.length == 5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTeamRosterStatus({
    required Team team,
    required bool hasRoster,
    required GameRoster? roster,
    required bool isStartingFiveComplete,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasRoster ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasRoster ? Colors.green[300]! : Colors.red[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRoster ? Icons.check_circle : Icons.cancel,
                color: hasRoster ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  team.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasRoster ? Colors.green[800] : Colors.red[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (hasRoster) ...[
            // Show player count with validation
            Row(
              children: [
                Icon(
                  roster!.players.length >= 10 ? Icons.check : Icons.warning,
                  color: roster.players.length >= 10 ? Colors.green : Colors.orange,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Players: ${roster.players.length}${roster.players.length < 10 ? " (Min: 10)" : ""}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: roster.players.length >= 10 ? Colors.green[700] : Colors.orange[700],
                    fontWeight: roster.players.length < 10 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Show starting five status
            Row(
              children: [
                Icon(
                  isStartingFiveComplete ? Icons.check : Icons.warning,
                  color: isStartingFiveComplete ? Colors.green : Colors.orange,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Starting Five: ${isStartingFiveComplete ? "✓ Complete" : "✗ Incomplete"}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isStartingFiveComplete ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Show possession readiness
            if (roster.players.length >= 10 && isStartingFiveComplete) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.play_arrow,
                    color: Colors.green,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ready for possessions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            Text(
              'No roster created',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSetupStatusText(Game game) {
    final hasRosters = _hasRosters(game);
    final hasStartingFives = _hasStartingFives(game);
    final hasHomeRoster = _hasHomeRoster(game);
    final hasAwayRoster = _hasAwayRoster(game);

    if (!hasRosters) {
      if (!hasHomeRoster && !hasAwayRoster) {
        return 'Create rosters for both teams to continue (10-12 players each)';
      } else if (!hasHomeRoster) {
        return 'Create roster for ${game.homeTeam.name} to continue';
      } else if (!hasAwayRoster) {
        return 'Create roster for ${game.awayTeam.name} to continue';
      }
    } else if (!hasStartingFives) {
      final homeStartingFiveComplete = game.homeTeamRoster!.startingFive.length == 5;
      final awayStartingFiveComplete = game.awayTeamRoster!.startingFive.length == 5;
      
      if (!homeStartingFiveComplete && !awayStartingFiveComplete) {
        return 'Select starting five for both teams to enable possession logging';
      } else if (!homeStartingFiveComplete) {
        return 'Select starting five for ${game.homeTeam.name} to enable possession logging';
      } else if (!awayStartingFiveComplete) {
        return 'Select starting five for ${game.awayTeam.name} to enable possession logging';
      }
    } else {
      return 'Game setup complete! You can now log possessions.';
    }
    
    return 'Game setup in progress...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Analysis'),
        actions: [],
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

          return Row(
            children: [
              // Main content area
              Expanded(
                child: Column(
                  children: [
                    // Game Setup Section
                    _buildGameSetupSection(game),
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
                      // Score display
                      if (game.homeTeamScore != null && game.awayTeamScore != null) ...[
                        Text(
                          '${game.homeTeamScore} - ${game.awayTeamScore}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                      ],
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
                ),
              ),
              // Right sidebar
              _buildRightSidebar(game),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRightSidebar(Game game) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Analytics buttons section
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    final userTeams = context.read<TeamCubit>().state.teams;
                    final userTeamInGame = userTeams.firstWhere(
                      (t) => t.id == game.homeTeam.id || t.id == game.awayTeam.id,
                      orElse: () => game.homeTeam,
                    );
                    context.go('/games/${game.id}/post-game-report?teamId=${userTeamInGame.id}');
                  },
                  tooltip: 'Post Game Report',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.assessment,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    context.go('/games/${game.id}/advanced-report');
                  },
                  tooltip: 'Advanced Post-Game Report',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Match Stats button
          IconButton(
            tooltip: 'Match Stats',
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              context.go('/games/${widget.gameId}/stats');
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Player Stats button
          IconButton(
            tooltip: 'Player Stats',
            icon: const Icon(Icons.people),
            onPressed: () {
              context.go('/games/${widget.gameId}/player-stats');
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Add New Possession button (only when setup is complete)
          BlocBuilder<GameDetailCubit, GameDetailState>(
            builder: (context, state) {
              final game = state.game;
              final canAddPossessions = _canAddPossessions(game);
              
              if (!canAddPossessions) {
                return const SizedBox.shrink();
              }
              
              return Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/games/${widget.gameId}/add-possession');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(height: 4),
                      Text(
                        'Add\nPossession',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          // Load/Reload possessions button (always available)
          BlocBuilder<GameDetailCubit, GameDetailState>(
            builder: (context, state) {
              final game = state.game;
              final hasPossessions = game?.possessions.isNotEmpty ?? false;
              
              return Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingMorePossessions ? null : _loadPossessionsFromDatabase,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _isLoadingMorePossessions 
                        ? Colors.grey 
                        : (hasPossessions ? Colors.orange : Colors.blueGrey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLoadingMorePossessions ? Icons.hourglass_empty : Icons.download,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoadingMorePossessions 
                            ? 'Loading...' 
                            : (hasPossessions ? 'Reload' : 'Load\nPossessions'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const Spacer(),
        ],
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
    final teamWithBall = possession.team?.team;

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
                  const SizedBox(height: 12),
                ],
                
                // --- PLAYER INFORMATION SECTION ---
                if (possession.playersOnCourt.isNotEmpty || possession.defensivePlayersOnCourt.isNotEmpty) ...[
                  Text(
                    'Players on Court:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Offensive team players
                  if (possession.playersOnCourt.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${teamWithBall.name}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: possession.playersOnCourt.map((player) => 
                              Chip(
                                label: Text(
                                  '${player.displayName}${player.jerseyNumber != null ? ' #${player.jerseyNumber}' : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.blue.shade100,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Defensive team players
                  if (possession.defensivePlayersOnCourt.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${opponent.name}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: possession.defensivePlayersOnCourt.map((player) => 
                              Chip(
                                label: Text(
                                  '${player.displayName}${player.jerseyNumber != null ? ' #${player.jerseyNumber}' : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.red.shade100,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Player attribution (who scored, assisted, etc.)
                  if (possession.scorer != null || possession.assistedBy != null) ...[
                    const Divider(height: 16),
                    Text(
                      'Player Attribution:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (possession.scorer != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.sports_basketball, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Scored by: ${possession.scorer!.displayName}${possession.scorer!.jerseyNumber != null ? ' #${possession.scorer!.jerseyNumber}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    if (possession.assistedBy != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.handshake, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Assisted by: ${possession.assistedBy!.displayName}${possession.assistedBy!.jerseyNumber != null ? ' #${possession.assistedBy!.jerseyNumber}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    if (possession.blockedBy != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.block, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Blocked by: ${possession.blockedBy!.displayName}${possession.blockedBy!.jerseyNumber != null ? ' #${possession.blockedBy!.jerseyNumber}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    if (possession.stolenBy != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.trending_up, size: 16, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(
                            'Stolen by: ${possession.stolenBy!.displayName}${possession.stolenBy!.jerseyNumber != null ? ' #${possession.stolenBy!.jerseyNumber}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    if (possession.fouledBy != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.warning, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Fouled by: ${possession.fouledBy!.displayName}${possession.fouledBy!.jerseyNumber != null ? ' #${possession.fouledBy!.jerseyNumber}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                  
                  const SizedBox(height: 12),
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
