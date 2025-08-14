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
    // Safely parse the list of players
    var playerList = (json['players'] as List? ?? [])
        .map((playerJson) => User.fromJson(playerJson))
        .toList();

    // Safely parse the list of coaches
    var coachList = (json['coaches'] as List? ?? [])
        .map((coachJson) => User.fromJson(coachJson))
        .toList();

    return Team(
      id: json['id'],
      name: json['name'],
      players: playerList,
      coaches: coachList,
    );
  }
}
