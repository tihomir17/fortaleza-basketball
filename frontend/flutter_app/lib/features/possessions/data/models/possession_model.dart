// lib/features/possessions/data/models/possession_model.dart

import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';

class Possession {
  final int id;
  final Game? game;
  final Team? team; // The team that had this possession
  final Team? opponent;
  final String startTimeInGame;
  final int durationSeconds;
  final int quarter;
  final String outcome;
  final String offensiveSequence;
  final String defensiveSequence;  

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
  });

  factory Possession.fromJson(Map<String, dynamic> json) {
    final possession = Possession(
      id: json['id'],
      game: json['game'] is Map<String, dynamic> ? Game.fromJson(json['game']) : null,
      team: json['team'] is Map<String, dynamic> ? Team.fromJson(json['team']) : null,
      opponent: json['opponent'] != null ? Team.fromJson(json['opponent']) : null,      
      startTimeInGame: json['start_time_in_game'] ?? '00:00',
      durationSeconds: json['duration_seconds'] ?? 0,
      quarter: json['quarter'] ?? 1,
      outcome: json['outcome'] ?? 'OTHER',
      offensiveSequence: json['offensive_sequence'] ?? '',
      defensiveSequence: json['defensive_sequence'] ?? '',
    );
    
    return possession;
  }
}
