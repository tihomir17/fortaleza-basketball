// lib/features/games/presentation/screens/games_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GAMES'),
        // We can add a "Create Game" button here later
      ),
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          if (state.status == GameStatus.loading ||
              state.status == GameStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == GameStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'Failed to load games.'),
            );
          }
          if (state.status == GameStatus.success && state.games.isEmpty) {
            return const Center(child: Text('No games have been created yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: state.games.length,
            itemBuilder: (context, index) {
              final game = state.games[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: const Icon(Icons.event_note_outlined),
                  title: Text(
                    '${game.homeTeam.name} vs ${game.awayTeam.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    game.gameDate != null
                        ? DateFormat.yMMMd().format(game.gameDate)
                        : "No date",
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    // Navigate to the detail screen for this specific game
                    context.go('/games/${game.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
