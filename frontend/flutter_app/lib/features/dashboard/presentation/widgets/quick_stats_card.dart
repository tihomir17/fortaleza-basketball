// lib/features/dashboard/presentation/widgets/quick_stats_card.dart

import 'package:flutter/material.dart';
import '../../data/models/dashboard_data.dart';

class QuickStatsCard extends StatelessWidget {
  final QuickStats stats;

  const QuickStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'Quick Stats',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total Games',
                    value: stats.totalGames.toString(),
                    icon: Icons.sports_basketball,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Total Possessions',
                    value: stats.totalPossessions.toString(),
                    icon: Icons.timeline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Recent Possessions',
                    value: stats.recentPossessions.toString(),
                    icon: Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Avg/Game',
                    value: stats.avgPossessionsPerGame.toString(),
                    icon: Icons.analytics,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
