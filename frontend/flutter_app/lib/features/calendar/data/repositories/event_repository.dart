// lib/features/calendar/data/repositories/event_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/calendar_event_model.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class EventRepository {
  final http.Client _client = http.Client();

  /// Fetches all calendar events (practices, etc.) visible to the current user.
  Future<List<CalendarEvent>> getAllEvents(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/events/');
    logger.d('EventRepository: Fetching all events from $url');
    try {
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final bodyText = response.body;
        final dynamic decoded = json.decode(bodyText);
        List<dynamic> items;
        if (decoded is List) {
          items = decoded;
          logger.d('EventRepository: Parsed top-level List with ${items.length} items.');
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['results'] is List) {
            items = decoded['results'] as List<dynamic>;
            logger.d('EventRepository: Parsed List from "results" with ${items.length} items.');
          } else if (decoded['events'] is List) {
            items = decoded['events'] as List<dynamic>;
            logger.d('EventRepository: Parsed List from "events" with ${items.length} items.');
          } else {
            logger.e('EventRepository: Unexpected JSON shape. Keys=${decoded.keys.toList()}');
            throw Exception('Unexpected events payload shape. Expected List or keys [results|events].');
          }
        } else {
          logger.e('EventRepository: Unexpected JSON root type: ${decoded.runtimeType}');
          throw Exception('Unexpected events payload type: ${decoded.runtimeType}');
        }
        logger.i('EventRepository: Loaded ${items.length} events.');
        return items.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        logger.e('EventRepository: Failed to load events. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to load calendar events. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      logger.e('EventRepository: Error fetching events: $e');
      throw Exception('Error fetching calendar events: $e');
    }
  }

  /// Creates a new calendar event.
  Future<CalendarEvent> createEvent({
    required String token,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    required String eventType,
    int? teamId,
    List<int>? attendeeIds,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/events/');
    logger.d('EventRepository: Creating event "$title" at $url');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          // Convert DateTime to ISO 8601 string format for the backend
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'event_type': eventType,
          'team': teamId,
          'attendees': attendeeIds ?? [],
        }),
      );
      if (response.statusCode == 201) {
        logger.i('EventRepository: Event "$title" created successfully.');
        return CalendarEvent.fromJson(json.decode(response.body));
      } else {
        logger.e('EventRepository: Failed to create event. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to create event. Server response: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('EventRepository: Error creating event: $e');
      throw Exception('An error occurred while creating the event: $e');
    }
  }

  Future<void> deleteEvent({
    required String token,
    required int eventId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/events/$eventId/');
    logger.d('EventRepository: Deleting event $eventId at $url');
    final response = await _client.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      logger.e('EventRepository: Failed to delete event $eventId. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to delete event.');
    }
    logger.i('EventRepository: Event $eventId deleted successfully.');
  }

  Future<CalendarEvent> updateEvent({
    required String token,
    required int eventId, // The ID of the event to update
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    required String eventType,
    int? teamId,
    List<int>? attendeeIds,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/events/$eventId/');
    logger.d('EventRepository: Updating event $eventId at $url');
    try {
      // Use PUT for a full update of the event object
      final response = await _client.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'event_type': eventType,
          'team': teamId,
          'attendees': attendeeIds ?? [],
        }),
      );
      if (response.statusCode == 200) {
        // 200 OK is the success code for PUT
        logger.i('EventRepository: Event $eventId updated successfully.');
        return CalendarEvent.fromJson(json.decode(response.body));
      } else {
        logger.e('EventRepository: Failed to update event $eventId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to update event. Server response: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('EventRepository: Error updating event $eventId: $e');
      throw Exception('An error occurred while updating the event: $e');
    }
  }
}
