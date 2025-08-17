// lib/features/competitions/data/models/competition_model.dart
import '../../../teams/data/models/team_model.dart';

class Competition {
  final int id;
  final String name;
  final String season;
  final List<Team> teams;

  Competition({
    required this.id,
    required this.name,
    required this.season,
    required this.teams,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    final teamListData = json['teams'] as List<dynamic>? ?? [];
    final teams = teamListData.map((teamJson) => Team.fromJson(teamJson)).toList();

    return Competition(
      id: json['id'],
      name: json['name'],
      season: json['season'],
      teams: teams,
    );
  }
}