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
    // Safely parse nested creator object
    final createdByData = json['created_by'] as Map<String, dynamic>?;
    final createdBy = createdByData != null ? User.fromJson(createdByData) : null;

    // Safely parse list of player objects with explicit casting
    final playersData = json['players'] as List<dynamic>? ?? [];
    final players = playersData.map((p) => User.fromJson(p as Map<String, dynamic>)).toList();

    // Safely parse list of coach objects with explicit casting
    final coachesData = json['coaches'] as List<dynamic>? ?? [];
    final coaches = coachesData.map((c) => User.fromJson(c as Map<String, dynamic>)).toList();

    return Team(
      id: json['id'],
      name: json['name'] as String? ?? 'Unnamed Team',
      createdBy: createdBy,
      players: players,
      coaches: coaches,
      competitionId: json['competition'] as int?,
    );
  }
}