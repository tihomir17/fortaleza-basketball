import 'package:fortaleza_basketball_analytics/main.dart'; // Import for global logger

// lib/features/calendar/data/models/calendar_event_model.dart

class CalendarEvent {
  final int id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String eventType;
  final int? teamId;
  final List<int> attendeeIds;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.eventType,
    this.teamId,
    required this.attendeeIds,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    // Accept multiple possible shapes and element types
    final dynamic raw = json['attendees'] ?? json['attendee_ids'] ?? json['attendeeIds'];
    final List<int> attendeeIds = [];
    if (raw is List) {
      for (final dynamic item in raw) {
        if (item is int) {
          attendeeIds.add(item);
        } else if (item is String) {
          final parsed = int.tryParse(item);
          if (parsed != null) attendeeIds.add(parsed);
        } else if (item is Map<String, dynamic>) {
          // Common shapes: {id: 123}, {user: 123}, {attendee_id: 123}
          final dynamic byId = item['id'] ?? item['user'] ?? item['attendee_id'] ?? item['attendeeId'];
          if (byId is int) {
            attendeeIds.add(byId);
          } else if (byId is String) {
            final parsed = int.tryParse(byId);
            if (parsed != null) attendeeIds.add(parsed);
          }
        }
      }
    }
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      eventType: json['event_type'],
      teamId: json['team'],
      attendeeIds: attendeeIds,
    );
  }
}
