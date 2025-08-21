// lib/features/games/presentation/screens/games_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart'; // Import the AppBar
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int? _selectedTeamId;

  @override
  Widget build(BuildContext context) {
    final userTeams = context.watch<TeamCubit>().state.teams;

    return Scaffold(
      appBar: const UserProfileAppBar(title: 'GAME ANALYSIS'),
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
                // Use the NEW filteredGames list from the state for the UI
                if (state.filteredGames.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No games found for the selected team.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: state.filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = state.filteredGames[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        leading: const Icon(Icons.event_note_outlined),
                        title: Text(
                          '${game.homeTeam?.name ?? "N/A"} vs ${game.awayTeam?.name ?? "N/A"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          game.gameDate != null
                              ? DateFormat.yMMMd().format(game.gameDate!)
                              : "No date",
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onTap: () => context.go('/games/${game.id}'),
                      ),
                    );
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
