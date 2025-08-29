import 'package:flutter_app/main.dart'; // Import for global logger

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
    logger.d('CalendarEvent.fromJson: Creating CalendarEvent object from JSON.');
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      eventType: json['event_type'],
      teamId: json['team'],
      attendeeIds: List<int>.from(json['attendees'] ?? []),
    );
  }
}
