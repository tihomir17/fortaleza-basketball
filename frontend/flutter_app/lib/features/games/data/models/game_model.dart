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
  List<Possession> possessions; // Make mutable for dynamic loading
  final int? homeTeamScore; // <-- ADD THIS
  final int? awayTeamScore; // <-- ADD THIS
  
  // Lightweight possession statistics for list view
  final int totalPossessions;
  final int offensivePossessions;
  final int defensivePossessions;
  final double avgOffensivePossessionTime;

  Game({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.gameDate,
    this.competitionId,
    this.possessions = const [],
    this.homeTeamScore,
    this.awayTeamScore,
    this.totalPossessions = 0,
    this.offensivePossessions = 0,
    this.defensivePossessions = 0,
    this.avgOffensivePossessionTime = 0.0,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // Safely get the list of possessions from the JSON (empty for lightweight list view)
    final possessionListData = json['possessions'] as List<dynamic>? ?? [];
    
    // Correctly parse the raw list into a List<Possession>
    final List<Possession> parsedPossessions = possessionListData
        .map((p) => Possession.fromJson(p as Map<String, dynamic>))
        .toList();

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
      
      // Add lightweight possession statistics
      totalPossessions: json['total_possessions'] as int? ?? 0,
      offensivePossessions: json['offensive_possessions'] as int? ?? 0,
      defensivePossessions: json['defensive_possessions'] as int? ?? 0,
      avgOffensivePossessionTime: (json['avg_offensive_possession_time'] as num?)?.toDouble() ?? 0.0,
    );

    return game;
  }
}
