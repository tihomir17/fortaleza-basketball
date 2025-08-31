// lib/features/games/presentation/screens/games_screen.dart

// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import 'package:flutter_app/features/games/presentation/widgets/game_card.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int? _selectedTeamId;
  String? _selectedOutcome;
  int? _selectedQuarter;
  bool _showOnlyUserTeamGames = false;
  bool _showAnalytics = false;

  void _refreshGames() {
    final token = context.read<AuthCubit>().state.token;
    if (token != null) {
      context.read<GameCubit>().refreshGames(token: token);
    }
  }

  void _generateReport() {
    // TODO: Implement report generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report generation coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userTeams = context.watch<TeamCubit>().state.teams;

    return Scaffold(
      appBar: UserProfileAppBar(
        title: 'GAME ANALYSIS',
        onRefresh: _refreshGames,
        actions: [
          IconButton(
            icon: Icon(_showAnalytics ? Icons.analytics : Icons.analytics_outlined),
            onPressed: () => setState(() => _showAnalytics = !_showAnalytics),
            tooltip: 'Toggle Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.summarize),
            onPressed: _generateReport,
            tooltip: 'Generate Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Filters Section
          _buildFiltersSection(userTeams),
          
          // Analytics Summary (if enabled)
          if (_showAnalytics) _buildAnalyticsSummary(),
          
          // Games List
          Expanded(
            child: BlocBuilder<GameCubit, GameState>(
              builder: (context, state) {
                if (state.status == GameStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == GameStatus.failure) {
                  return Center(
                    child: Text(state.errorMessage ?? 'Failed to load games.'),
                  );
                }
                if (state.filteredGames.isEmpty) {
                  return const Center(
                    child: Text('No games found for the selected filters.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(4.0),
                  itemCount: state.filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = state.filteredGames[index];
                    return GameCard(game: game);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(List<Team> userTeams) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Team Filter
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedTeamId,
                  hint: const Text('Filter by Team...'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Teams'),
                    ),
                    ...userTeams.map(
                      (team) => DropdownMenuItem(
                        value: team.id, 
                        child: Text(team.name),
                      ),
                    ),
                  ],
                  onChanged: (teamId) {
                    setState(() => _selectedTeamId = teamId);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _showOnlyUserTeamGames,
                onChanged: (value) {
                  setState(() => _showOnlyUserTeamGames = value);
                  _applyFilters();
                },
              ),
              const Text('My Teams Only'),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Additional Filters Row
          Row(
            children: [
              // Outcome Filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedOutcome,
                  hint: const Text('Outcome...'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Outcomes')),
                    const DropdownMenuItem<String?>(value: 'W', child: Text('Wins')),
                    const DropdownMenuItem<String?>(value: 'L', child: Text('Losses')),
                  ],
                  onChanged: (outcome) {
                    setState(() => _selectedOutcome = outcome);
                    _applyFilters();
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Quarter Filter
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedQuarter,
                  hint: const Text('Quarter...'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All Quarters')),
                    const DropdownMenuItem<int?>(value: 1, child: Text('Q1')),
                    const DropdownMenuItem<int?>(value: 2, child: Text('Q2')),
                    const DropdownMenuItem<int?>(value: 3, child: Text('Q3')),
                    const DropdownMenuItem<int?>(value: 4, child: Text('Q4')),
                  ],
                  onChanged: (quarter) {
                    setState(() => _selectedQuarter = quarter);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        if (state.filteredGames.isEmpty) return const SizedBox();
        
        final games = state.filteredGames;
        final userTeams = context.read<TeamCubit>().state.teams;
        
        // Calculate analytics
        int totalGames = games.length;
        int wins = 0;
        int losses = 0;
        int totalPossessions = 0;
        int totalOffensivePossessions = 0;
        int totalDefensivePossessions = 0;
        double totalPossessionTime = 0;
        
        for (final game in games) {
          final isFinished = game.homeTeamScore != null && game.awayTeamScore != null;
          if (isFinished) {
            final userTeamInGame = userTeams.firstWhere(
              (t) => t.id == game.homeTeam.id || t.id == game.awayTeam.id,
              orElse: () => game.homeTeam,
            );
            
            final isHomeTeam = userTeamInGame.id == game.homeTeam.id;
            final homeWon = game.homeTeamScore! > game.awayTeamScore!;
            final userWon = isHomeTeam ? homeWon : !homeWon;
            
            if (userWon) {
              wins++;
            } else {
              losses++;
            }
          }
          
          totalPossessions += game.possessions.length;
          totalOffensivePossessions += game.possessions.where((p) => p.offensiveSequence.isNotEmpty).length;
          totalDefensivePossessions += game.possessions.where((p) => p.defensiveSequence.isNotEmpty).length;
          totalPossessionTime += game.possessions.fold(0.0, (sum, p) => sum + p.durationSeconds);
        }
        
        final winRate = totalGames > 0 ? (wins / totalGames * 100) : 0;
        final avgPossessionTime = totalPossessions > 0 ? totalPossessionTime / totalPossessions : 0;
        
        return Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _AnalyticsCard(
                    title: 'Games',
                    value: totalGames.toString(),
                    icon: Icons.sports_basketball,
                    color: Colors.blue,
                  ),
                  _AnalyticsCard(
                    title: 'Win Rate',
                    value: '${winRate.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  _AnalyticsCard(
                    title: 'Wins',
                    value: wins.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  _AnalyticsCard(
                    title: 'Losses',
                    value: losses.toString(),
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _AnalyticsCard(
                    title: 'Possessions',
                    value: totalPossessions.toString(),
                    icon: Icons.sports_basketball,
                    color: Colors.orange,
                  ),
                  _AnalyticsCard(
                    title: 'Offensive',
                    value: totalOffensivePossessions.toString(),
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  _AnalyticsCard(
                    title: 'Defensive',
                    value: totalDefensivePossessions.toString(),
                    icon: Icons.shield,
                    color: Colors.purple,
                  ),
                  _AnalyticsCard(
                    title: 'Avg Time',
                    value: '${avgPossessionTime.toStringAsFixed(1)}s',
                    icon: Icons.timer,
                    color: Colors.indigo,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters() {
    final userTeams = context.read<TeamCubit>().state.teams;
    final userTeamIds = userTeams.map((team) => team.id).toList();
    
    context.read<GameCubit>().applyAdvancedFilters(
      teamId: _selectedTeamId,
      outcome: _selectedOutcome,
      quarter: _selectedQuarter,
      showOnlyUserTeams: _showOnlyUserTeamGames,
      userTeamIds: userTeamIds,
      timeRange: null, // Games screen doesn't use time range filtering
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeTeam = game.homeTeam;
    final awayTeam = game.awayTeam;
    final bool isFinished =
        game.homeTeamScore != null && game.awayTeamScore != null;

    // Determine Win/Loss state for the home team
    bool homeTeamWon = false;
    if (isFinished) {
      homeTeamWon = game.homeTeamScore! > game.awayTeamScore!;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/games/${game.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Team vs Team Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TeamDisplay(team: homeTeam),
                  Text(
                    "VS",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Anton',
                    ),
                  ),
                  _TeamDisplay(team: awayTeam),
                ],
              ),
              const SizedBox(height: 16),
              // Score and Date Row
              if (isFinished)
                _ScoreDisplay(
                  homeScore: game.homeTeamScore!,
                  awayScore: game.awayTeamScore!,
                  homeWon: homeTeamWon,
                )
              else
                Text(
                  game.gameDate != null
                      ? DateFormat('EEE, MMM d, yyyy').format(game.gameDate)
                      : "Date TBD",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper for displaying a team's logo/name
class _TeamDisplay extends StatelessWidget {
  final Team? team;
  const _TeamDisplay({this.team});

  @override
  Widget build(BuildContext context) {
    if (team == null) return const SizedBox(width: 80);
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            child: Text(
              team!.name.isNotEmpty ? team!.name[0] : 'T',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            team!.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Helper for displaying the final score
class _ScoreDisplay extends StatelessWidget {
  final int homeScore;
  final int awayScore;
  final bool homeWon;
  const _ScoreDisplay({
    required this.homeScore,
    required this.awayScore,
    required this.homeWon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    final lossStyle = theme.textTheme.headlineMedium?.copyWith(
      color: Colors.grey,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$homeScore', style: homeWon ? winStyle : lossStyle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('-', style: theme.textTheme.headlineSmall),
        ),
        Text('$awayScore', style: !homeWon ? winStyle : lossStyle),
      ],
    );
  }
}
