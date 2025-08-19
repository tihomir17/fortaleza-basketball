// lib/features/games/data/models/game_model.dart
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
    return Game(
      id: json['id'],
      // If the key is null or not a map, the result will be null.
      homeTeam: Team.fromJson(json['home_team']),
      awayTeam: Team.fromJson(json['away_team']),

      gameDate: DateTime.parse(json['game_date']),

      competitionId: json['competition'],

      possessions: json['possessions'] ?? [],
    );
  }
}
