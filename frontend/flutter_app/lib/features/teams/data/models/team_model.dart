// lib/features/teams/data/models/team_model.dart
import 'package:fortaleza_basketball_analytics/features/authentication/data/models/user_model.dart';

class Team {
  final int id;
  final String name;
  final User? createdBy;
  final List<User> players;
  final List<User> coaches;
  final List<User> staff;
  final int? competitionId;
  final String? logoUrl;

  Team({
    required this.id,
    required this.name,
    this.createdBy,
    required this.players,
    required this.coaches,
    this.staff = const [],
    this.competitionId,
    this.logoUrl,
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
      staff: (json['staff'] as List<dynamic>? ?? [])
          .map((s) => User.fromJson(s as Map<String, dynamic>))
          .toList(),
      competitionId: compId,
      logoUrl: json['logo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy?.toJson(),
      'players': players.map((p) => p.toJson()).toList(),
      'coaches': coaches.map((c) => c.toJson()).toList(),
      'staff': staff.map((s) => s.toJson()).toList(),
      'competitionId': competitionId,
      'logoUrl': logoUrl,
    };
  }
}
