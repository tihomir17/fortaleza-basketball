// lib/features/possessions/data/models/possession_model.dart

import 'package:fortaleza_basketball_analytics/features/games/data/models/game_model.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/data/models/user_model.dart';
import 'package:fortaleza_basketball_analytics/features/games/data/models/game_roster_model.dart';

class Possession {
  final int id;
  final Game? game;
  final GameRoster? team; // The team that had this possession
  final GameRoster? opponent;
  final String startTimeInGame;
  final int durationSeconds;
  final int quarter;
  final String outcome;
  final String offensiveSequence;
  final String defensiveSequence;  
  final int pointsScored;
  final bool isOffensiveRebound;
  final int offensiveReboundCount;
  final User? scorer;
  final User? assistedBy;
  final User? blockedBy;
  final User? stolenBy;
  final User? fouledBy;
  final List<User> playersOnCourt;
  final List<User> defensivePlayersOnCourt;
  final List<User> offensiveReboundPlayers;

  Possession({
    required this.id,
    this.game,
    this.team,
    this.opponent,
    required this.startTimeInGame,
    required this.durationSeconds,
    required this.quarter,
    required this.outcome,
    required this.offensiveSequence,
    required this.defensiveSequence,
    required this.pointsScored,
    required this.isOffensiveRebound,
    required this.offensiveReboundCount,
    this.scorer,
    this.assistedBy,
    this.blockedBy,
    this.stolenBy,
    this.fouledBy,
    this.playersOnCourt = const [],
    this.defensivePlayersOnCourt = const [],
    this.offensiveReboundPlayers = const [],
  });

  factory Possession.fromJson(Map<String, dynamic> json) {
    final possession = Possession(
      id: json['id'],
      game: json['game'] is Map<String, dynamic> ? Game.fromJson(json['game']) : null,
      team: json['team'] is Map<String, dynamic> ? GameRoster.fromJson(json['team']) : null,
      opponent: json['opponent'] != null ? GameRoster.fromJson(json['opponent']) : null,      
      startTimeInGame: json['start_time_in_game'] ?? '00:00',
      durationSeconds: json['duration_seconds'] ?? 0,
      quarter: json['quarter'] ?? 1,
      outcome: json['outcome'] ?? 'OTHER',
      offensiveSequence: json['offensive_sequence'] ?? '',
      defensiveSequence: json['defensive_sequence'] ?? '',
      pointsScored: json['points_scored'] ?? 0,
      isOffensiveRebound: json['is_offensive_rebound'] ?? false,
      offensiveReboundCount: json['offensive_rebound_count'] ?? 0,
      scorer: json['scorer'] is Map<String, dynamic> ? User.fromJson(json['scorer']) : null,
      assistedBy: json['assisted_by'] is Map<String, dynamic> ? User.fromJson(json['assisted_by']) : null,
      blockedBy: json['blocked_by'] is Map<String, dynamic> ? User.fromJson(json['blocked_by']) : null,
      stolenBy: json['stolen_by'] is Map<String, dynamic> ? User.fromJson(json['stolen_by']) : null,
      fouledBy: json['fouled_by'] is Map<String, dynamic> ? User.fromJson(json['fouled_by']) : null,
      playersOnCourt: (json['players_on_court'] as List<dynamic>?)
              ?.map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList() ?? const [],
      defensivePlayersOnCourt: (json['defensive_players_on_court'] as List<dynamic>?)
              ?.map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList() ?? const [],
      offensiveReboundPlayers: (json['offensive_rebound_players'] as List<dynamic>?)
              ?.map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList() ?? const [],
    );
    
    return possession;
  }
}
