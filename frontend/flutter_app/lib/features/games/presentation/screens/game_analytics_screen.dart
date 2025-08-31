// lib/features/games/presentation/screens/game_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class GameAnalyticsScreen extends StatefulWidget {
  const GameAnalyticsScreen({super.key});

  @override
  State<GameAnalyticsScreen> createState() => _GameAnalyticsScreenState();
}

class _GameAnalyticsScreenState extends State<GameAnalyticsScreen> {
  int? _selectedTeamId;
  String _selectedTimeRange = 'Last 30 Days';
  final String _selectedMetric = 'Win Rate';

  @override
  Widget build(BuildContext context) {
    final userTeams = context.watch<TeamCubit>().state.teams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(userTeams),
          
          // Analytics Content
          Expanded(
            child: BlocBuilder<GameCubit, GameState>(
              builder: (context, state) {
                if (state.status == GameStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state.filteredGames.isEmpty) {
                  return const Center(
                    child: Text('No games found for analysis.'),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildPerformanceOverview(state.filteredGames, userTeams),
                      const SizedBox(height: 24),
                      _buildPossessionAnalysis(state.filteredGames),
                      const SizedBox(height: 24),
                      _buildTrendAnalysis(state.filteredGames, userTeams),
                      const SizedBox(height: 24),
                      _buildDetailedStats(state.filteredGames, userTeams),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<Team> userTeams) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedTeamId,
                  hint: const Text('Select Team'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All Teams')),
                    ...userTeams.map((team) => DropdownMenuItem(
                      value: team.id,
                      child: Text(team.name),
                    )),
                  ],
                  onChanged: (teamId) {
                    setState(() => _selectedTeamId = teamId);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeRange,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                    DropdownMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
                    DropdownMenuItem(value: 'Last 90 Days', child: Text('Last 90 Days')),
                    DropdownMenuItem(value: 'Season', child: Text('Season')),
                  ],
                  onChanged: (timeRange) {
                    setState(() => _selectedTimeRange = timeRange!);
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

  Widget _buildPerformanceOverview(List<Game> games, List<Team> userTeams) {
    final stats = _calculatePerformanceStats(games, userTeams);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Win Rate',
                    value: '${stats.winRate.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: Colors.green,
                    subtitle: '${stats.wins}W - ${stats.losses}L',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Avg Points',
                    value: stats.avgPoints.toStringAsFixed(1),
                    icon: Icons.sports_basketball,
                    color: Colors.blue,
                    subtitle: 'Per Game',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Possessions',
                    value: stats.totalPossessions.toString(),
                    icon: Icons.timer,
                    color: Colors.orange,
                    subtitle: 'Total',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPossessionAnalysis(List<Game> games) {
    final possessionStats = _calculatePossessionStats(games);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Possession Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Offensive',
                    value: possessionStats.offensivePossessions.toString(),
                    icon: Icons.trending_up,
                    color: Colors.green,
                    subtitle: '${possessionStats.offensivePercentage.toStringAsFixed(1)}%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Defensive',
                    value: possessionStats.defensivePossessions.toString(),
                    icon: Icons.shield,
                    color: Colors.purple,
                    subtitle: '${possessionStats.defensivePercentage.toStringAsFixed(1)}%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Avg Time',
                    value: '${possessionStats.avgPossessionTime.toStringAsFixed(1)}s',
                    icon: Icons.timer,
                    color: Colors.indigo,
                    subtitle: 'Per Possession',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis(List<Game> games, List<Team> userTeams) {
    final trends = _calculateTrends(games, userTeams);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TrendCard(
                    title: 'Recent Form',
                    value: trends.recentForm,
                    icon: trends.recentFormIcon,
                    color: trends.recentFormColor,
                    subtitle: 'Last 5 Games',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrendCard(
                    title: 'Home Record',
                    value: '${trends.homeWinRate.toStringAsFixed(1)}%',
                    icon: Icons.home,
                    color: Colors.blue,
                    subtitle: '${trends.homeWins}W - ${trends.homeLosses}L',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrendCard(
                    title: 'Away Record',
                    value: '${trends.awayWinRate.toStringAsFixed(1)}%',
                    icon: Icons.flight,
                    color: Colors.orange,
                    subtitle: '${trends.awayWins}W - ${trends.awayLosses}L',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(List<Game> games, List<Team> userTeams) {
    final detailedStats = _calculateDetailedStats(games, userTeams);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Statistics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _DetailedStatsTable(stats: detailedStats),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    final userTeams = context.read<TeamCubit>().state.teams;
    final userTeamIds = userTeams.map((team) => team.id).toList();
    
    context.read<GameCubit>().applyAdvancedFilters(
      teamId: _selectedTeamId,
      userTeamIds: userTeamIds,
      timeRange: _selectedTimeRange,
    );
  }

  void _exportReport() {
    // TODO: Implement report export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report export coming soon!')),
    );
  }

  // Helper methods for calculating statistics
  _PerformanceStats _calculatePerformanceStats(List<Game> games, List<Team> userTeams) {
    int wins = 0, losses = 0, totalPoints = 0, totalPossessions = 0;
    
    for (final game in games) {
      if (game.homeTeamScore != null && game.awayTeamScore != null) {
        final userTeamInGame = userTeams.firstWhere(
          (t) => t.id == game.homeTeam.id || t.id == game.awayTeam.id,
          orElse: () => game.homeTeam,
        );
        
        final isHomeTeam = userTeamInGame.id == game.homeTeam.id;
        final homeWon = game.homeTeamScore! > game.awayTeamScore!;
        final userWon = isHomeTeam ? homeWon : !homeWon;
        
        if (userWon) {
          wins++;
          totalPoints += isHomeTeam ? game.homeTeamScore! : game.awayTeamScore!;
        } else {
          losses++;
          totalPoints += isHomeTeam ? game.homeTeamScore! : game.awayTeamScore!;
        }
      }
      
      totalPossessions += game.possessions.length;
    }
    
    final totalGames = wins + losses;
    final winRate = totalGames > 0 ? (wins / totalGames * 100.0) : 0.0;
    final avgPoints = totalGames > 0 ? totalPoints / totalGames : 0.0;
    
    return _PerformanceStats(
      wins: wins,
      losses: losses,
      winRate: winRate,
      avgPoints: avgPoints,
      totalPossessions: totalPossessions,
    );
  }

  _PossessionStats _calculatePossessionStats(List<Game> games) {
    int totalPossessions = 0;
    int offensivePossessions = 0;
    int defensivePossessions = 0;
    double totalTime = 0.0;
    
    for (final game in games) {
      totalPossessions += game.possessions.length;
      offensivePossessions += game.possessions.where((p) => p.offensiveSequence.isNotEmpty).length;
      defensivePossessions += game.possessions.where((p) => p.defensiveSequence.isNotEmpty).length;
      totalTime += game.possessions.fold(0.0, (sum, p) => sum + p.durationSeconds);
    }
    
    final offensivePercentage = totalPossessions > 0 ? (offensivePossessions / totalPossessions * 100.0) : 0.0;
    final defensivePercentage = totalPossessions > 0 ? (defensivePossessions / totalPossessions * 100.0) : 0.0;
    final avgPossessionTime = totalPossessions > 0 ? totalTime / totalPossessions : 0.0;
    
    return _PossessionStats(
      offensivePossessions: offensivePossessions,
      defensivePossessions: defensivePossessions,
      offensivePercentage: offensivePercentage,
      defensivePercentage: defensivePercentage,
      avgPossessionTime: avgPossessionTime,
    );
  }

  _TrendStats _calculateTrends(List<Game> games, List<Team> userTeams) {
    // Sort games by date (most recent first)
    final sortedGames = List<Game>.from(games);
    sortedGames.sort((a, b) => b.gameDate.compareTo(a.gameDate));
    
    // Calculate recent form (last 5 games)
    int recentWins = 0;
    for (int i = 0; i < 5 && i < sortedGames.length; i++) {
      final game = sortedGames[i];
      if (game.homeTeamScore != null && game.awayTeamScore != null) {
        final userTeamInGame = userTeams.firstWhere(
          (t) => t.id == game.homeTeam.id || t.id == game.awayTeam.id,
          orElse: () => game.homeTeam,
        );
        
        final isHomeTeam = userTeamInGame.id == game.homeTeam.id;
        final homeWon = game.homeTeamScore! > game.awayTeamScore!;
        final userWon = isHomeTeam ? homeWon : !homeWon;
        
        if (userWon) recentWins++;
      }
    }
    
    final recentForm = recentWins >= 4 ? 'Excellent' : 
                      recentWins >= 3 ? 'Good' : 
                      recentWins >= 2 ? 'Average' : 
                      recentWins >= 1 ? 'Poor' : 'Very Poor';
    
    final recentFormIcon = recentWins >= 4 ? Icons.trending_up : 
                          recentWins >= 3 ? Icons.trending_flat : 
                          Icons.trending_down;
    
    final recentFormColor = recentWins >= 4 ? Colors.green : 
                           recentWins >= 3 ? Colors.orange : 
                           Colors.red;
    
    // Calculate home/away records
    int homeWins = 0, homeLosses = 0, awayWins = 0, awayLosses = 0;
    
    for (final game in games) {
      if (game.homeTeamScore != null && game.awayTeamScore != null) {
        final userTeamInGame = userTeams.firstWhere(
          (t) => t.id == game.homeTeam.id || t.id == game.awayTeam.id,
          orElse: () => game.homeTeam,
        );
        
        final isHomeTeam = userTeamInGame.id == game.homeTeam.id;
        final homeWon = game.homeTeamScore! > game.awayTeamScore!;
        final userWon = isHomeTeam ? homeWon : !homeWon;
        
        if (isHomeTeam) {
          if (userWon) {
            homeWins++;
          } else {
            homeLosses++;
          }
        } else {
          if (userWon) {
            awayWins++;
          } else {
            awayLosses++;
          }
        }
      }
    }
    
    final homeWinRate = (homeWins + homeLosses) > 0 ? (homeWins / (homeWins + homeLosses) * 100.0) : 0.0;
    final awayWinRate = (awayWins + awayLosses) > 0 ? (awayWins / (awayWins + awayLosses) * 100.0) : 0.0;
    
    return _TrendStats(
      recentForm: recentForm,
      recentFormIcon: recentFormIcon,
      recentFormColor: recentFormColor,
      homeWins: homeWins,
      homeLosses: homeLosses,
      homeWinRate: homeWinRate,
      awayWins: awayWins,
      awayLosses: awayLosses,
      awayWinRate: awayWinRate,
    );
  }

  _DetailedStats _calculateDetailedStats(List<Game> games, List<Team> userTeams) {
    // Calculate various detailed statistics
    int totalGames = 0;
    int totalPoints = 0;
    int totalOpponentPoints = 0;
    int totalPossessions = 0;
    double totalPossessionTime = 0;
    
    for (final game in games) {
      if (game.homeTeamScore != null && game.awayTeamScore != null) {
        totalGames++;
        final userTeamInGame = userTeams.firstWhere(
          (t) => t.id == game.homeTeam.id || t.id == game.awayTeam.id,
          orElse: () => game.homeTeam,
        );
        
        final isHomeTeam = userTeamInGame.id == game.homeTeam.id;
        totalPoints += isHomeTeam ? game.homeTeamScore! : game.awayTeamScore!;
        totalOpponentPoints += isHomeTeam ? game.awayTeamScore! : game.homeTeamScore!;
      }
      
      totalPossessions += game.possessions.length;
      totalPossessionTime += game.possessions.fold(0.0, (sum, p) => sum + p.durationSeconds);
    }
    
    final avgPointsFor = totalGames > 0 ? totalPoints / totalGames : 0.0;
    final avgPointsAgainst = totalGames > 0 ? totalOpponentPoints / totalGames : 0.0;
    final avgPossessionTime = totalPossessions > 0 ? totalPossessionTime / totalPossessions : 0.0;
    
    return _DetailedStats(
      totalGames: totalGames,
      avgPointsFor: avgPointsFor,
      avgPointsAgainst: avgPointsAgainst,
      totalPossessions: totalPossessions,
      avgPossessionTime: avgPossessionTime,
    );
  }
}

// Data classes for statistics
class _PerformanceStats {
  final int wins;
  final int losses;
  final double winRate;
  final double avgPoints;
  final int totalPossessions;
  
  _PerformanceStats({
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.avgPoints,
    required this.totalPossessions,
  });
}

class _PossessionStats {
  final int offensivePossessions;
  final int defensivePossessions;
  final double offensivePercentage;
  final double defensivePercentage;
  final double avgPossessionTime;
  
  _PossessionStats({
    required this.offensivePossessions,
    required this.defensivePossessions,
    required this.offensivePercentage,
    required this.defensivePercentage,
    required this.avgPossessionTime,
  });
}

class _TrendStats {
  final String recentForm;
  final IconData recentFormIcon;
  final Color recentFormColor;
  final int homeWins;
  final int homeLosses;
  final double homeWinRate;
  final int awayWins;
  final int awayLosses;
  final double awayWinRate;
  
  _TrendStats({
    required this.recentForm,
    required this.recentFormIcon,
    required this.recentFormColor,
    required this.homeWins,
    required this.homeLosses,
    required this.homeWinRate,
    required this.awayWins,
    required this.awayLosses,
    required this.awayWinRate,
  });
}

class _DetailedStats {
  final int totalGames;
  final double avgPointsFor;
  final double avgPointsAgainst;
  final int totalPossessions;
  final double avgPossessionTime;
  
  _DetailedStats({
    required this.totalGames,
    required this.avgPointsFor,
    required this.avgPointsAgainst,
    required this.totalPossessions,
    required this.avgPossessionTime,
  });
}

// Widget classes
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  
  const _TrendCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedStatsTable extends StatelessWidget {
  final _DetailedStats stats;
  
  const _DetailedStatsTable({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: [
            _TableCell('Metric', isHeader: true),
            _TableCell('Value', isHeader: true),
          ],
        ),
        TableRow(
          children: [
            _TableCell('Total Games'),
            _TableCell(stats.totalGames.toString()),
          ],
        ),
        TableRow(
          children: [
            _TableCell('Average Points For'),
            _TableCell(stats.avgPointsFor.toStringAsFixed(1)),
          ],
        ),
        TableRow(
          children: [
            _TableCell('Average Points Against'),
            _TableCell(stats.avgPointsAgainst.toStringAsFixed(1)),
          ],
        ),
        TableRow(
          children: [
            _TableCell('Total Possessions'),
            _TableCell(stats.totalPossessions.toString()),
          ],
        ),
        TableRow(
          children: [
            _TableCell('Average Possession Time'),
            _TableCell('${stats.avgPossessionTime.toStringAsFixed(1)}s'),
          ],
        ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  
  const _TableCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 13,
        ),
      ),
    );
  }
}
