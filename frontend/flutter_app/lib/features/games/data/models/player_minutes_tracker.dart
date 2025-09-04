// lib/features/games/data/models/player_minutes_tracker.dart

import 'package:flutter_app/features/authentication/data/models/user_model.dart';
import 'package:flutter_app/features/possessions/data/models/possession_model.dart';

class PlayerMinutesTracker {
  final Map<int, int> playerSecondsOnCourt = {}; // playerId -> total seconds
  final Map<int, List<TimeSegment>> playerTimeSegments = {}; // playerId -> list of time segments
  
  // Track when players enter/exit court
  void addTimeSegment(int playerId, int startTime, int endTime, int quarter) {
    if (!playerTimeSegments.containsKey(playerId)) {
      playerTimeSegments[playerId] = [];
    }
    
    playerTimeSegments[playerId]!.add(TimeSegment(
      startTime: startTime,
      endTime: endTime,
      quarter: quarter,
    ));
    
    // Update total seconds
    final duration = endTime - startTime;
    playerSecondsOnCourt[playerId] = (playerSecondsOnCourt[playerId] ?? 0) + duration;
  }
  
  // Get total minutes for a player
  int getPlayerMinutes(int playerId) {
    return playerSecondsOnCourt[playerId] ?? 0;
  }
  
  // Get formatted minutes (MM:SS)
  String getPlayerMinutesFormatted(int playerId) {
    final seconds = getPlayerMinutes(playerId);
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // Validate total team time (should be 200:00 for 4 quarters, 25:00 per OT)
  bool validateTeamTime(int overtimePeriods) {
    final expectedTotalSeconds = (200 + (overtimePeriods * 25)) * 60; // Convert to seconds
    final actualTotalSeconds = playerSecondsOnCourt.values.fold(0, (sum, seconds) => sum + seconds);
    
    // Allow small tolerance (1 second) for rounding
    return (actualTotalSeconds - expectedTotalSeconds).abs() <= 1;
  }
  
  // Get total team time
  int getTotalTeamTime() {
    return playerSecondsOnCourt.values.fold(0, (sum, seconds) => sum + seconds);
  }
  
  // Get formatted total team time
  String getTotalTeamTimeFormatted() {
    final totalSeconds = getTotalTeamTime();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(3, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Process possessions to build time tracking for a specific team
  void processPossessionsForTeam(List<Possession> possessions, String teamId) {
    for (final possession in possessions) {
      // Only process possessions where this team was involved
      if (possession.team?.team.id.toString() == teamId || 
          possession.opponent?.team.id.toString() == teamId) {
        
        final startTime = _parseTimeToSeconds(possession.startTimeInGame);
        final endTime = startTime + possession.durationSeconds;
        
        // Track offensive team players (if this team was offensive)
        if (possession.team?.team.id.toString() == teamId) {
          for (final player in possession.playersOnCourt) {
            addTimeSegment(player.id, startTime, endTime, possession.quarter);
          }
        }
        
        // Track defensive team players (if this team was defensive)
        if (possession.opponent?.team.id.toString() == teamId) {
          for (final player in possession.defensivePlayersOnCourt) {
            addTimeSegment(player.id, startTime, endTime, possession.quarter);
          }
        }
      }
    }
  }
  
  // Process all possessions (legacy method - use processPossessionsForTeam instead)
  void processPossessions(List<Possession> possessions) {
    processPossessionsForTeam(possessions, '');
  }
  
  // Parse time string (MM:SS) to seconds
  int _parseTimeToSeconds(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return minutes * 60 + seconds;
    }
    return 0;
  }
}

class TimeSegment {
  final int startTime; // seconds from start of quarter
  final int endTime;   // seconds from start of quarter
  final int quarter;   // which quarter this segment belongs to
  
  TimeSegment({
    required this.startTime,
    required this.endTime,
    required this.quarter,
  });
  
  int get duration => endTime - startTime;
}
