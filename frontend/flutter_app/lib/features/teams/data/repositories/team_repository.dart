// lib/features/teams/data/repositories/team_repository.dart

import 'dart:convert';
import 'package:flutter_app/features/authentication/data/models/user_model.dart';
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

  Future<Team> getTeamDetails({
    required String token,
    required int teamId,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/teams/$teamId/',
    ); // <-- Note the teamId in the URL

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // The response body is a single JSON object, not a list
        Map<String, dynamic> body = json.decode(response.body);
        // We parse it directly into a Team object
        return Team.fromJson(body);
      } else {
        print(
          'Failed to load team details. Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
        throw Exception('Failed to load team details from API');
      }
    } catch (e) {
      print('Error fetching team details: $e');
      throw Exception('Error fetching team details: $e');
    }
  }

  Future<Team> updateTeam({
    required String token,
    required int teamId,
    required String newName,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/teams/$teamId/');

    try {
      // We use PATCH for partial updates, as we are only changing the name.
      final response = await _client.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': newName}),
      );

      if (response.statusCode == 200) {
        // 200 OK is the success code for PATCH/PUT
        final Map<String, dynamic> body = json.decode(response.body);
        return Team.fromJson(body);
      } else {
        throw Exception(
          'Failed to update team. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while updating the team: $e');
    }
  }

  Future<Team> createTeam({required String token, required String name}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/teams/');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 201) {
        // 201 Created is the success code
        final Map<String, dynamic> body = json.decode(response.body);
        return Team.fromJson(body);
      } else {
        throw Exception(
          'Failed to create team. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while creating the team: $e');
    }
  }

  Future<void> addMemberToTeam({
    required String token,
    required int teamId,
    required int userId,
    required String role, // 'player' or 'coach'
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/teams/$teamId/add_member/');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'user_id': userId, 'role': role}),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to add member. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while adding a member: $e');
    }
  }

  Future<void> removeMemberFromTeam({
    required String token,
    required int teamId,
    required int userId,
    required String role,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/teams/$teamId/remove_member/');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'user_id': userId, 'role': role}),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to remove member. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while removing a member: $e');
    }
  }

  Future<User> createAndAddPlayer({
    required String token,
    required int teamId,
    required String email,
    required String username,
    String? firstName,
    String? lastName,
    int? jerseyNumber,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/teams/$teamId/create_and_add_player/',
    );
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'email': email,
          'username': username,
          'first_name': firstName,
          'last_name': lastName,
          'jersey_number': jerseyNumber, 
        }),
      );
      if (response.statusCode == 201) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to add player. Server response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred while adding a player: $e');
    }
  }
}
