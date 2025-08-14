// lib/features/teams/data/repositories/team_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../../../../features/authentication/data/repositories/auth_repository.dart';
import '../models/team_model.dart';

class TeamRepository {
  final http.Client _client = http.Client();
  final AuthRepository _authRepository;

  TeamRepository({required AuthRepository authRepository}) : _authRepository = authRepository;

  Future<List<Team>> getMyTeams() async {
    final token = _authRepository.authToken;
    if (token == null) {
      // If there's no token, the user is not logged in. Return an empty list.
      throw Exception('User is not authenticated');
    }

    final url = Uri.parse('${ApiClient.baseUrl}/teams/');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // <-- CRITICAL: Send the auth token
        },
      );

      if (response.statusCode == 200) {
        // Decode the response body (which is a JSON string) into a Dart List
        List<dynamic> body = json.decode(response.body);
        // Map each item in the list to a Team object
        List<Team> teams = body.map((dynamic item) => Team.fromJson(item)).toList();
        return teams;
      } else {
        throw Exception('Failed to load teams');
      }
    } catch (e) {
      throw Exception('Error fetching teams: $e');
    }
  }
}