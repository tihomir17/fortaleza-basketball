// lib/features/teams/data/models/team_model.dart
import 'package:flutter_app/features/authentication/data/models/user_model.dart';

class Team {
  final int id;
  final String name;
  final User? createdBy;
  final List<User> players;
  final List<User> coaches;
  final int? competitionId;

  Team({
    required this.id,
    required this.name,
    this.createdBy,
    required this.players,
    required this.coaches,
    this.competitionId,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    int? compId;
    if (json['competition'] is int) {
      compId = json['competition'];
    } else if (json['competition'] is Map<String, dynamic>) {
      compId = json['competition']['id'];
    }

    return Team(
      id: json['id'],
      name: json['name'] as String? ?? 'Unnamed Team',
      createdBy: json['created_by'] is Map<String, dynamic>
          ? User.fromJson(json['created_by'])
          : null,
      players: (json['players'] as List<dynamic>? ?? [])
          .map((p) => User.fromJson(p as Map<String, dynamic>))
          .toList(),
      coaches: (json['coaches'] as List<dynamic>? ?? [])
          .map((c) => User.fromJson(c as Map<String, dynamic>))
          .toList(),
      competitionId: compId,
    );
  }
}
