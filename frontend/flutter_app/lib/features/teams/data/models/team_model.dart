// lib/features/teams/data/models/team_model.dart

import '../../../authentication/data/models/user_model.dart';

class Team {
  final int id;
  final String name;
  final List<User> players;
  final List<User> coaches;
  final User? createdBy;
  final int? competitionId;

  Team({
    required this.id,
    required this.name,
    required this.players,
    required this.coaches,
    this.createdBy,
    this.competitionId,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    // Safely parse the list of players, defaulting to an empty list if null
    final playersData = json['players'] as List<dynamic>? ?? [];
    final players = playersData
        .map((playerJson) => User.fromJson(playerJson))
        .toList();

    // Safely parse the list of coaches, defaulting to an empty list if null
    final coachesData = json['coaches'] as List<dynamic>? ?? [];
    final coaches = coachesData
        .map((coachJson) => User.fromJson(coachJson))
        .toList();

    // Safely parse the 'created_by' field. If it's null in the JSON, our 'createdBy' property will be null.
    final createdByData = json['created_by'] as Map<String, dynamic>?;
    final createdBy = createdByData != null
        ? User.fromJson(createdByData)
        : null;

    return Team(
      // The 'id' field is the most likely culprit for the error.
      // We ensure it defaults to a value like 0 if it's somehow null.
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unnamed Team',
      players: players,
      coaches: coaches,
      createdBy: createdBy,
      competitionId: json['competition'],
    );
  }
}
