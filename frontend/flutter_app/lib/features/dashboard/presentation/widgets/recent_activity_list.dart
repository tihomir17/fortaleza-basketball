// lib/features/dashboard/presentation/widgets/recent_activity_list.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/dashboard_data.dart';

class RecentActivityList extends StatelessWidget {
  final List<RecentActivity> activities;

  const RecentActivityList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
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
                    Icons.history_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Activity',
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
                      Icons.history_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent activity',
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
                  Icons.history_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
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
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _ActivityCard(activity: activity);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final RecentActivity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/games/${activity.game.id}'),
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
                    '${activity.game.homeTeam} vs ${activity.game.awayTeam}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOutcomeColor(activity.outcome),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatOutcome(activity.outcome),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Q${activity.quarter} • ${activity.team}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                if (activity.opponent != null) ...[
                  const Text(' • '),
                  Text(
                    'vs ${activity.opponent}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatOffensiveSet(activity.offensiveSet),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimeAgo(activity.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getOutcomeColor(String outcome) {
    switch (outcome) {
      case 'MADE_2PTS':
      case 'MADE_3PTS':
      case 'MADE_FTS':
        return Colors.green;
      case 'MISSED_2PTS':
      case 'MISSED_3PTS':
      case 'MISSED_FTS':
        return Colors.orange;
      case 'TURNOVER':
      case 'FOUL':
        return Colors.red;
      case 'REBOUND':
      case 'STEAL':
      case 'BLOCK':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatOutcome(String outcome) {
    switch (outcome) {
      case 'MADE_2PTS':
        return '2PT MADE';
      case 'MISSED_2PTS':
        return '2PT MISS';
      case 'MADE_3PTS':
        return '3PT MADE';
      case 'MISSED_3PTS':
        return '3PT MISS';
      case 'MADE_FTS':
        return 'FT MADE';
      case 'MISSED_FTS':
        return 'FT MISS';
      case 'TURNOVER':
        return 'TO';
      case 'FOUL':
        return 'FOUL';
      case 'REBOUND':
        return 'REB';
      case 'STEAL':
        return 'STEAL';
      case 'BLOCK':
        return 'BLOCK';
      default:
        return outcome.replaceAll('_', ' ');
    }
  }

  String _formatOffensiveSet(String offensiveSet) {
    switch (offensiveSet) {
      case 'PICK_AND_ROLL':
        return 'Pick & Roll';
      case 'PICK_AND_POP':
        return 'Pick & Pop';
      case 'HANDOFF':
        return 'Handoff';
      case 'BACKDOOR':
        return 'Backdoor';
      case 'FLARE':
        return 'Flare';
      case 'DOWN_SCREEN':
        return 'Down Screen';
      case 'UP_SCREEN':
        return 'Up Screen';
      case 'CROSS_SCREEN':
        return 'Cross Screen';
      case 'POST_UP':
        return 'Post Up';
      case 'ISOLATION':
        return 'Isolation';
      case 'TRANSITION':
        return 'Transition';
      case 'OFFENSIVE_REBOUND':
        return 'Offensive Rebound';
      case 'OTHER':
        return 'Other';
      default:
        return offensiveSet.replaceAll('_', ' ');
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
