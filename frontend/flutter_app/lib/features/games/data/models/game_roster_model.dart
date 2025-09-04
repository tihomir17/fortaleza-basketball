// lib/features/games/data/models/game_roster_model.dart

import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/features/authentication/data/models/user_model.dart';

class GameRoster {
  final int id;
  final Team team;
  final List<User> players; // Exactly 12 players
  final List<User> startingFive; // First 5 players who started
  final List<User> benchPlayers; // Remaining 7 players

  GameRoster({
    required this.id,
    required this.team,
    required this.players,
    required this.startingFive,
    required this.benchPlayers,
  });

  // Validate that we have exactly 12 players
  bool get isValid => players.length == 12 && startingFive.length == 5 && benchPlayers.length == 7;

  // Get total time for validation (200:00 for 4 quarters, 25:00 per overtime)
  int getTotalTeamMinutes(int overtimePeriods) {
    return 200 + (overtimePeriods * 25); // 200 minutes base + 25 per OT
  }

  // Get player by ID
  User? getPlayerById(int id) {
    try {
      return players.firstWhere((player) => player.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if player is in roster
  bool isPlayerInRoster(int playerId) {
    return players.any((player) => player.id == playerId);
  }

  // Check if player is starting five
  bool isStartingFive(int playerId) {
    return startingFive.any((player) => player.id == playerId);
  }

  factory GameRoster.fromJson(Map<String, dynamic> json) {
    final team = Team.fromJson(json['team']);
    final playersList = (json['players'] as List<dynamic>)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
    
    // First 5 players are starters
    final startingFive = playersList.take(5).toList();
    final benchPlayers = playersList.skip(5).toList();

    return GameRoster(
      id: json['id'],
      team: team,
      players: playersList,
      startingFive: startingFive,
      benchPlayers: benchPlayers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team': team.toJson(),
      'players': players.map((e) => e.toJson()).toList(),
      'startingFive': startingFive.map((e) => e.toJson()).toList(),
      'benchPlayers': benchPlayers.map((e) => e.toJson()).toList(),
    };
  }
}
