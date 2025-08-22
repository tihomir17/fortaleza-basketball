// lib/features/games/presentation/screens/games_screen.dart

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

  void _refreshGames() {
    final token = context.read<AuthCubit>().state.token;
    if (token != null) {
      context.read<GameCubit>().fetchGames(token: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userTeams = context.watch<TeamCubit>().state.teams;

    return Scaffold(
      appBar: UserProfileAppBar(
        title: 'GAME ANALYSIS',
        onRefresh: _refreshGames,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: DropdownButtonFormField<int?>(
              value: _selectedTeamId,
              hint: const Text('Filter by Team...'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All My Teams'),
                ),
                ...userTeams.map(
                  (team) =>
                      DropdownMenuItem(value: team.id, child: Text(team.name)),
                ),
              ],
              onChanged: (teamId) {
                setState(() => _selectedTeamId = teamId);
                context.read<GameCubit>().filterGamesByTeam(teamId);
              },
            ),
          ),
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
                    child: Text('No games found for the selected team.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: state.filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = state.filteredGames[index];
                    // Use our new, dedicated GameCard widget
                    return GameCard(game: game);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/log-possession'),
        tooltip: 'Log New Possession',
        child: const Icon(Icons.add_chart),
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
