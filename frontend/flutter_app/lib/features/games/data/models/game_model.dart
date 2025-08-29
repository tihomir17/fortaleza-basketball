// lib/features/games/data/models/game_model.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_app/features/possessions/data/models/possession_model.dart';

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
    // Safely get the list of possessions from the JSON
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

    return Game(
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
  }
}
