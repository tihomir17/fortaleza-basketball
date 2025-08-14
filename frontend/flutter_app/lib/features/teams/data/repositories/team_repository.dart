// lib/features/teams/data/repositories/team_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/team_model.dart';

class TeamRepository {
  final http.Client _client = http.Client();

  // The repository no longer stores an instance of AuthRepository
  TeamRepository();

  Future<List<Team>> getMyTeams({required String token}) async {
    // Restore the correct endpoint URL
    final url = Uri.parse('${ApiClient.baseUrl}/teams/');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Restore the real parsing logic
        List<dynamic> body = json.decode(response.body);
        List<Team> teams = body
            .map((dynamic item) => Team.fromJson(item))
            .toList();
        return teams;
      } else {
        print('Failed to load teams. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load teams from API');
      }
    } catch (e) {
      print('Error fetching teams: $e');
      throw Exception('Error fetching teams: $e');
    }
  }
}
