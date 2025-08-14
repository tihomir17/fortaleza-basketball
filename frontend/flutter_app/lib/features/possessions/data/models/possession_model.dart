// lib/features/possessions/data/models/possession_model.dart

import '../../../authentication/data/models/user_model.dart';

class Possession {
  final int id;
  final int teamId;
  final int? playDefinitionId;
  final List<User> playersOnCourt;
  final DateTime startTimestamp;
  final DateTime? endTimestamp;
  final String? outcome;
  // tracking_data can be a Map<String, dynamic> for flexibility
  final Map<String, dynamic>? trackingData;

  Possession({
    required this.id,
    required this.teamId,
    this.playDefinitionId,
    required this.playersOnCourt,
    required this.startTimestamp,
    this.endTimestamp,
    this.outcome,
    this.trackingData,
  });

  factory Possession.fromJson(Map<String, dynamic> json) {
    var playerList = (json['players_on_court'] as List? ?? [])
        .map((playerJson) => User.fromJson(playerJson))
        .toList();

    return Possession(
      id: json['id'],
      teamId: json['team'],
      playDefinitionId: json['play_definition'],
      playersOnCourt: playerList,
      startTimestamp: DateTime.parse(json['start_timestamp']),
      endTimestamp: json['end_timestamp'] != null
          ? DateTime.parse(json['end_timestamp'])
          : null,
      outcome: json['outcome'],
      trackingData: json['tracking_data'],
    );
  }
}
