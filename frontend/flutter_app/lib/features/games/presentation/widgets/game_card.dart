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
    );

    if (isFinished && userTeamInGame != null) {}

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/games/${game.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
              if (isFinished)
                _ScoreDisplay(
                  homeScore: game.homeTeamScore!,
                  awayScore: game.awayTeamScore!,
                  homeWon: homeTeamWon,
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      game.gameDate != null
                          ? DateFormat(
                              'EEE, MMM d, yyyy @ ',
                            ).format(game.gameDate)
                          : "Date TBD",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      game.gameDate != null
                          ? DateFormat.jm().format(game.gameDate)
                          : "",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
