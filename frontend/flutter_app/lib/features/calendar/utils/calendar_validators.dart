// lib/features/calendar/utils/calendar_validators.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fortaleza_basketball_analytics/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/games/data/models/game_model.dart';
import '../data/models/calendar_event_model.dart';
import 'package:fortaleza_basketball_analytics/main.dart'; // Import for global logger

class CalendarValidators {
  static String? validateNoConflicts({
    required BuildContext context,
    required DateTime newStartTime,
    required DateTime newEndTime,
    int? eventToIgnoreId, // Used when editing an event
  }) {
    // Get the master list of all games and events from the cubit
    final calendarState = context.read<CalendarCubit>().state;
    final allItems = calendarState.allCalendarItems;

    // The time buffer for conflicts (3 hours)
    const buffer = Duration(hours: 3);

    for (final item in allItems) {
      DateTime existingStartTime;
      DateTime existingEndTime;

      if (item is Game) {
        logger.d('CalendarValidators: Checking game conflict with ${item.homeTeam.name}');
        existingStartTime = item.gameDate;
        // Assume a game lasts for a certain duration if no end time is stored
        existingEndTime = existingStartTime.add(const Duration(hours: 2));
      } else if (item is CalendarEvent) {
        // Skip the event we are currently editing
        if (item.id == eventToIgnoreId) {
          logger.d('CalendarValidators: Ignoring event ${item.id} as it is being edited.');
          continue;
        }
        logger.d('CalendarValidators: Checking event conflict with ${item.title}');
        existingStartTime = item.startTime;
        existingEndTime = item.endTime;
      } else {
        logger.w('CalendarValidators: Skipping unknown calendar item type.');
        continue; // Skip unknown types
      }

      // Calculate the time window for the existing event, including the buffer
      final conflictWindowStart = existingStartTime.subtract(buffer);
      final conflictWindowEnd = existingEndTime.add(buffer);

      // Check for overlap
      if (newStartTime.isBefore(conflictWindowEnd) &&
          newEndTime.isAfter(conflictWindowStart)) {
        // A conflict was found!
        logger.w('CalendarValidators: Conflict detected with existing item: $item');
        return "Scheduling conflict detected with an existing event or game.";
      }
    }

    // No conflicts found
    logger.i('CalendarValidators: No scheduling conflicts detected.');
    return null;
  }
}
