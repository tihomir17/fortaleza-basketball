// lib/features/games/data/models/game_model.dart
// ignore_for_file: unused_import

import 'package:flutter/foundation.dart';
import 'package:flutter_app/features/possessions/data/models/possession_model.dart';
import 'package:flutter_app/core/logging/file_logger.dart';

import '../../../teams/data/models/team_model.dart';

class Game {
  final int id;
  // Make the teams potentially nullable
  final Team homeTeam;
  final Team awayTeam;
  final DateTime gameDate;
  final int? competitionId;
  final List<Possession> possessions; // Keep possessions for detail view
  final int? homeTeamScore; // <-- ADD THIS
  final int? awayTeamScore; // <-- ADD THIS

  Game({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.gameDate,
    this.competitionId,
    this.possessions = const [],
    this.homeTeamScore,
    this.awayTeamScore,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // Only log in debug mode to reduce overhead
    if (kDebugMode) {
      FileLogger().logPossessionData('Game.fromJson_raw', {
        'game_id': json['id'],
        'possessions_count': json['possessions']?.length ?? 0,
        'has_possessions': json['possessions'] != null,
      });
    }

    // Safely get the list of possessions from the JSON
    final possessionListData = json['possessions'] as List<dynamic>? ?? [];
    
    // Only log in debug mode to reduce overhead
    if (kDebugMode) {
      FileLogger().logPossessionData('Game.fromJson_possessions_raw', {
        'possession_list_length': possessionListData.length,
        'possession_list_type': possessionListData.runtimeType.toString(),
      });
    }
    
    // Correctly parse the raw list into a List<Possession>
    final List<Possession> parsedPossessions = possessionListData
        .map((p) => Possession.fromJson(p as Map<String, dynamic>))
        .toList();

    // Only log in debug mode to reduce overhead
    if (kDebugMode) {
      FileLogger().logPossessionData('Game.fromJson_possessions_parsed', {
        'parsed_possessions_count': parsedPossessions.length,
      });
    }

    // Safely parse the competition ID, which might be a Map or an int
    int? compId;
    if (json['competition'] is int) {
      compId = json['competition'];
    } else if (json['competition'] is Map<String, dynamic>) {
      compId = json['competition']['id'];
    }

    final game = Game(
      id: json['id'],
      // If the key is null or not a map, the result will be null.
      homeTeam: Team.fromJson(json['home_team']),
      awayTeam: Team.fromJson(json['away_team']),
      gameDate: DateTime.parse(json['game_date']),

      competitionId: compId,

      possessions: parsedPossessions,
      homeTeamScore: json['home_team_score'],
      awayTeamScore: json['away_team_score'],
    );

    // Only log in debug mode to reduce overhead
    if (kDebugMode) {
      FileLogger().logPossessionData('Game.fromJson_final', {
        'game_id': game.id,
        'final_possessions_count': game.possessions.length,
      });
    }

    return game;
  }
}
