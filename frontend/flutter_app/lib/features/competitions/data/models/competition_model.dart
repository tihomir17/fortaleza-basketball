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
    
    // We explicitly cast each item in the list to a Map<String, dynamic>
    // before passing it to the Team.fromJson factory.
    final teams = teamListData.map((teamJson) {
      return Team.fromJson(teamJson as Map<String, dynamic>);
    }).toList();

    return Competition(
      id: json['id'],
      name: json['name'] as String? ?? 'Unnamed Competition',
      season: json['season'] as String? ?? 'N/A',
      teams: teams,
    );
  }
}