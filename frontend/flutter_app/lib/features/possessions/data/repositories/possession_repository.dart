// lib/features/possessions/data/repositories/possession_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/possession_model.dart';

class PossessionRepository {
  final http.Client _client = http.Client();

  Future<Possession> createPossession({
    required String token,
    required int teamId,
    required int? opponentId,
    required String startTime,
    required int duration,
    required int quarter,
    required String outcome,
    required String offensiveSequence,
    required String defensiveSequence,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/possessions/');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'team_id': teamId,
          'opponent_id': opponentId,
          'start_time_in_game': startTime,
          'duration_seconds': duration,
          'quarter': quarter,
          'outcome': outcome,
          'offensive_sequence': offensiveSequence,
          'defensive_sequence': defensiveSequence,
        }),
      );
      if (response.statusCode == 201) {
        return Possession.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create possession. Server response: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred while creating possession: $e');
    }
  }
}