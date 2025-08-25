// lib/features/calendar/data/repositories/event_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/calendar_event_model.dart';

class EventRepository {
  final http.Client _client = http.Client();

  /// Fetches all calendar events (practices, etc.) visible to the current user.
  Future<List<CalendarEvent>> getAllEvents(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/events/');
    try {
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return body.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load calendar events. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
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
        return CalendarEvent.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to create event. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while creating the event: $e');
    }
  }

  Future<void> deleteEvent({
    required String token,
    required int eventId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/events/$eventId/');
    final response = await _client.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete event.');
    }
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
        return CalendarEvent.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to update event. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while updating the event: $e');
    }
  }
}
