// lib/features/teams/data/models/team_model.dart

import '../../../authentication/data/models/user_model.dart';

class Team {
  final int id;
  final String name;
  final List<User> players;
  final List<User> coaches;

  Team({
    required this.id,
    required this.name,
    required this.players,
    required this.coaches,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    // This is a safer way to parse lists that might be null or absent
    final playersData = json['players'] as List<dynamic>? ?? [];
    final players = playersData
        .map((playerJson) => User.fromJson(playerJson))
        .toList();

    final coachesData = json['coaches'] as List<dynamic>? ?? [];
    final coaches = coachesData
        .map((coachJson) => User.fromJson(coachJson))
        .toList();

    return Team(
      id: json['id'],
      name: json['name'],
      players: players,
      coaches: coaches,
    );
  }
}
