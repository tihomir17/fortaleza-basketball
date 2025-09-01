// lib/features/dashboard/presentation/widgets/upcoming_games_list.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/dashboard_data.dart';

class UpcomingGamesList extends StatelessWidget {
  final List<UpcomingGame> games;

  const UpcomingGamesList({super.key, required this.games});

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Games',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No upcoming games',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Games',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return _GameCard(game: game);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final UpcomingGame game;

  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final isToday = DateTime.now().difference(game.gameDate).inDays == 0;
    final isTomorrow = DateTime.now().difference(game.gameDate).inDays == -1;

    return InkWell(
      onTap: () => context.go('/games/${game.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${game.homeTeam} vs ${game.awayTeam}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isToday 
                        ? Theme.of(context).colorScheme.primary
                        : isTomorrow
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isToday 
                        ? 'TODAY'
                        : isTomorrow
                            ? 'TOMORROW'
                            : _formatDate(game.gameDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isToday || isTomorrow
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              game.competition,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(game.gameDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'TODAY';
    if (difference == 1) return 'TOMORROW';
    if (difference < 7) return '${date.weekday == 1 ? 'Mon' : date.weekday == 2 ? 'Tue' : date.weekday == 3 ? 'Wed' : date.weekday == 4 ? 'Thu' : date.weekday == 5 ? 'Fri' : date.weekday == 6 ? 'Sat' : 'Sun'}';
    
    return '${date.month}/${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
  }
}
