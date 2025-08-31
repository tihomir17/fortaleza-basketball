// lib/features/games/presentation/widgets/game_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import '../../data/models/game_model.dart';

class GameCard extends StatelessWidget {
  final Game game;
  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeTeam = game.homeTeam;
    final awayTeam = game.awayTeam;
    final isFinished = game.homeTeamScore != null && game.awayTeamScore != null;

    bool homeTeamWon = false;
    if (isFinished) {
      homeTeamWon = game.homeTeamScore! > game.awayTeamScore!;
    }

    // Check if one of the user's teams is in this game for W/L indication
    final userTeams = context.read<TeamCubit>().state.teams;
    final userTeamInGame = userTeams.firstWhere(
      (t) => t.id == homeTeam.id || t.id == awayTeam.id,
      orElse: () => homeTeam, // fallback
    );

    // Calculate quick stats
    // Use lightweight possession statistics from the model
    final totalPossessions = game.totalPossessions;
    final offensivePossessions = game.offensivePossessions;
    final defensivePossessions = game.defensivePossessions;
    final avgOffensivePossessionTime = game.avgOffensivePossessionTime;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/games/${game.id}'),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Compact header with teams and score
              Row(
                children: [
                  // Home team
                  Expanded(
                    flex: 2,
                    child: _CompactTeamDisplay(
                      team: homeTeam,
                      isWinner: isFinished && homeTeamWon,
                      isUserTeam: userTeamInGame.id == homeTeam.id,
                    ),
                  ),
                  
                  // VS and Score
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Text(
                          "VS",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'Anton',
                            color: Colors.grey[600],
                          ),
                        ),
                        if (isFinished) ...[
                          const SizedBox(height: 4),
                          _CompactScoreDisplay(
                            homeScore: game.homeTeamScore!,
                            awayScore: game.awayTeamScore!,
                            homeWon: homeTeamWon,
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          _GameDateDisplay(game: game),
                        ],
                      ],
                    ),
                  ),
                  
                  // Away team
                  Expanded(
                    flex: 2,
                    child: _CompactTeamDisplay(
                      team: awayTeam,
                      isWinner: isFinished && !homeTeamWon,
                      isUserTeam: userTeamInGame.id == awayTeam.id,
                    ),
                  ),
                ],
              ),
              
              // Quick stats row - show meaningful stats for all games
              const SizedBox(height: 8),
              _QuickStatsRow(
                totalPossessions: totalPossessions,
                offensivePossessions: offensivePossessions,
                defensivePossessions: defensivePossessions,
                avgOffensivePossessionTime: avgOffensivePossessionTime,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTeamDisplay extends StatelessWidget {
  final Team? team;
  final bool isWinner;
  final bool isUserTeam;
  
  const _CompactTeamDisplay({
    this.team,
    required this.isWinner,
    required this.isUserTeam,
  });

  @override
  Widget build(BuildContext context) {
    if (team == null) return const SizedBox();
    
    final theme = Theme.of(context);
    final backgroundColor = isUserTeam 
        ? theme.colorScheme.primary.withOpacity(0.1)
        : (isWinner ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1));
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: isUserTeam 
            ? Border.all(color: theme.colorScheme.primary, width: 1)
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: team!.logoUrl != null
                    ? NetworkImage(team!.logoUrl!)
                    : null,
                child: team!.logoUrl == null
                    ? Text(
                        team!.name.isNotEmpty ? team!.name[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              if (isUserTeam) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.person,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            team!.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: isWinner ? Colors.green[700] : null,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _CompactScoreDisplay extends StatelessWidget {
  final int homeScore;
  final int awayScore;
  final bool homeWon;
  
  const _CompactScoreDisplay({
    required this.homeScore,
    required this.awayScore,
    required this.homeWon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.green[700],
    );
    final lossStyle = TextStyle(
      fontSize: 16,
      color: Colors.grey[600],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$homeScore', style: homeWon ? winStyle : lossStyle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('-', style: TextStyle(color: Colors.grey[600])),
        ),
        Text('$awayScore', style: !homeWon ? winStyle : lossStyle),
      ],
    );
  }
}

class _GameDateDisplay extends StatelessWidget {
  final Game game;
  
  const _GameDateDisplay({required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.gameDate == null) {
      return Text(
        "Date TBD",
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
        ),
      );
    }
    
    return Column(
      children: [
        Text(
          DateFormat('MMM d').format(game.gameDate),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        Text(
          DateFormat('HH:mm').format(game.gameDate),
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final int totalPossessions;
  final int offensivePossessions;
  final int defensivePossessions;
  final double avgOffensivePossessionTime;
  
  const _QuickStatsRow({
    required this.totalPossessions,
    required this.offensivePossessions,
    required this.defensivePossessions,
    required this.avgOffensivePossessionTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Possession statistics
          _StatItem(
            icon: Icons.sports_basketball,
            label: 'Total',
            value: totalPossessions.toString(),
            color: theme.colorScheme.primary,
          ),
          _StatItem(
            icon: Icons.trending_up,
            label: 'Off',
            value: offensivePossessions.toString(),
            color: Colors.green[600]!,
          ),
          _StatItem(
            icon: Icons.shield,
            label: 'Def',
            value: defensivePossessions.toString(),
            color: Colors.orange[600]!,
          ),
          _StatItem(
            icon: Icons.timer,
            label: 'Avg Off',
            value: '${avgOffensivePossessionTime.toStringAsFixed(1)}s',
            color: Colors.purple[600]!,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isNA = value == 'N/A';
    final displayColor = isNA ? Colors.grey[400]! : color;
    
    return Column(
      children: [
        Icon(icon, size: 12, color: displayColor),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: displayColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Keep the old classes for backward compatibility
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
            backgroundColor: Theme.of(context).cardColor,
            backgroundImage: team!.logoUrl != null
                ? NetworkImage(team!.logoUrl!)
                : null,
            child: team!.logoUrl == null
                ? Text(
                    team!.name.isNotEmpty ? team!.name[0] : 'T',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
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
