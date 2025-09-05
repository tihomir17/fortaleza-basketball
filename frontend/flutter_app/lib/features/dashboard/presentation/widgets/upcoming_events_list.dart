// lib/features/dashboard/presentation/widgets/upcoming_events_list.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/dashboard_data.dart';

class UpcomingEventsList extends StatelessWidget {
  final List<UpcomingEvent> events;

  const UpcomingEventsList({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Events',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'No upcoming events for today',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Events',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Today',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...events.map((event) => _buildEventItem(context, event)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, UpcomingEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Event Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getEventColor(event.eventType).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getEventIcon(event.eventType),
              color: _getEventColor(event.eventType),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Event Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatEventTime(event.startTime, event.endTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Event Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getEventColor(event.eventType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatEventType(event.eventType),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getEventColor(event.eventType),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventTime(DateTime startTime, DateTime endTime) {
    final startFormat = DateFormat('HH:mm');
    final endFormat = DateFormat('HH:mm');
    return '${startFormat.format(startTime)} - ${endFormat.format(endTime)}';
  }

  String _formatEventType(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'SCOUTING_MEETING':
        return 'Scouting';
      case 'STRENGTH_CONDITIONING':
        return 'S&C';
      case 'INDIVIDUAL_PRACTICE':
        return 'Individual';
      case 'TEAM_PRACTICE':
        return 'Practice';
      case 'GAME':
        return 'Game';
      case 'TEAM_MEETING':
        return 'Meeting';
      case 'TRAVEL_BUS':
        return 'Travel (Bus)';
      case 'TRAVEL_PLANE':
        return 'Travel (Plane)';
      case 'TEAM_BUILDING':
        return 'Team Building';
      default:
        return eventType;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'SCOUTING_MEETING':
        return Icons.search_outlined;
      case 'STRENGTH_CONDITIONING':
        return Icons.fitness_center_outlined;
      case 'INDIVIDUAL_PRACTICE':
        return Icons.person_outlined;
      case 'TEAM_PRACTICE':
        return Icons.sports_basketball_outlined;
      case 'GAME':
        return Icons.sports_outlined;
      case 'TEAM_MEETING':
        return Icons.meeting_room_outlined;
      case 'TRAVEL_BUS':
        return Icons.directions_bus_outlined;
      case 'TRAVEL_PLANE':
        return Icons.flight_outlined;
      case 'TEAM_BUILDING':
        return Icons.group_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'SCOUTING_MEETING':
        return Colors.purple;
      case 'STRENGTH_CONDITIONING':
        return Colors.orange;
      case 'INDIVIDUAL_PRACTICE':
        return Colors.blue;
      case 'TEAM_PRACTICE':
        return Colors.green;
      case 'GAME':
        return Colors.red;
      case 'TEAM_MEETING':
        return Colors.indigo;
      case 'TRAVEL_BUS':
        return Colors.brown;
      case 'TRAVEL_PLANE':
        return Colors.cyan;
      case 'TEAM_BUILDING':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
