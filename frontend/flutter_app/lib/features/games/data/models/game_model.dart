// lib/features/games/data/models/game_model.dart
import '../../../teams/data/models/team_model.dart';

class Game {
  final int id;
  final Team homeTeam;
  final Team awayTeam;
  final DateTime gameDate;
  final int competitionId;

  Game({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.gameDate,
    required this.competitionId,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      homeTeam: Team.fromJson(json['home_team']),
      awayTeam: Team.fromJson(json['away_team']),
      gameDate: DateTime.parse(json['game_date']),
      competitionId: json['competition'],
    );
  }
}
