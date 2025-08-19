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
  final List<dynamic> possessions; // Keep possessions for detail view

  Game({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.gameDate,
    this.competitionId,
    this.possessions = const [],
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("\n--- INSIDE Game.fromJson ---");
      print("Parsing game with ID: ${json['id']}");
      // Log the raw data for the 'possessions' key BEFORE we try to parse it.
      print("Raw 'possessions' data received: ${json['possessions']}");
      print("Type of 'possessions' data: ${json['possessions'].runtimeType}");
      print("--- END OF LOGS ---\n");
    }
    // --- END OF DEBUGGING LOGS ---
    // Safely get the list of possessions from the JSON
    final possessionListData = json['possessions'] as List<dynamic>? ?? [];

    // Correctly parse the raw list into a List<Possession>
    final List<Possession> parsedPossessions = possessionListData.map((
      possessionJson,
    ) {
      return Possession.fromJson(possessionJson as Map<String, dynamic>);
    }).toList();

    if (kDebugMode) {
      print(parsedPossessions);
    }

    return Game(
      id: json['id'],
      // If the key is null or not a map, the result will be null.
      homeTeam: Team.fromJson(json['home_team']),
      awayTeam: Team.fromJson(json['away_team']),

      gameDate: DateTime.parse(json['game_date']),

      competitionId: json['competition'],

      possessions: parsedPossessions,
    );
  }
}
