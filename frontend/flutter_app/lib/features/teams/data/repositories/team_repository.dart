// lib/features/teams/data/repositories/team_repository.dart

import 'dart:convert';
import 'package:flutter_app/features/authentication/data/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/team_model.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class TeamRepository {
  final http.Client _client = http.Client();

  // The repository no longer stores an instance of AuthRepository
  TeamRepository();

  Future<List<Team>> getMyTeams({required String token}) async {
    // Restore the correct endpoint URL
    final url = Uri.parse('${ApiClient.baseUrl}/teams/');
    logger.d('TeamRepository: Fetching my teams from $url');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final status = response.statusCode;
      final bodyText = response.body;
      logger.d('TeamRepository: Response status=$status, body=${bodyText.length > 800 ? '${bodyText.substring(0, 800)}...<truncated>' : bodyText}');

      if (status == 200) {
        final dynamic decoded = json.decode(bodyText);
        List<dynamic> items;
        if (decoded is List) {
          items = decoded;
          logger.d('TeamRepository: Parsed top-level List with ${items.length} items.');
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['results'] is List) {
            items = decoded['results'] as List<dynamic>;
            logger.d('TeamRepository: Parsed List from "results" with ${items.length} items.');
          } else if (decoded['teams'] is List) {
            items = decoded['teams'] as List<dynamic>;
            logger.d('TeamRepository: Parsed List from "teams" with ${items.length} items.');
          } else {
            logger.e('TeamRepository: Unexpected JSON shape. Keys=${decoded.keys.toList()}');
            throw Exception('Unexpected teams payload shape. Expected List or keys [results|teams].');
          }
        } else {
          logger.e('TeamRepository: Unexpected JSON root type: ${decoded.runtimeType}');
          throw Exception('Unexpected teams payload type: ${decoded.runtimeType}');
        }

        final List<Team> teams = items
            .map((dynamic item) => Team.fromJson(item as Map<String, dynamic>))
            .toList();
        logger.i('TeamRepository: Loaded ${teams.length} teams.');
        return teams;
      } else {
        logger.e('TeamRepository: Failed to load teams. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load teams from API');
      }
    } catch (e) {
      logger.e('TeamRepository: Error fetching teams: $e');
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
    logger.d('TeamRepository: Fetching team details for $teamId at $url');

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
        logger.i('TeamRepository: Team $teamId details loaded.');
        return Team.fromJson(body);
      } else {
        logger.e('TeamRepository: Failed to load team $teamId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load team details from API');
      }
    } catch (e) {
      logger.e('TeamRepository: Error fetching team $teamId details: $e');
      throw Exception('Error fetching team details: $e');
    }
  }

  Future<Team> updateTeam({
    required String token,
    required int teamId,
    required String newName,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/teams/$teamId/');
    logger.d('TeamRepository: Updating team $teamId with name "$newName" at $url');

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
        logger.i('TeamRepository: Team $teamId updated successfully.');
        return Team.fromJson(body);
      } else {
        logger.e('TeamRepository: Failed to update team $teamId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to update team. Server response: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('TeamRepository: Error updating team $teamId: $e');
      throw Exception('An error occurred while updating the team: $e');
    }
  }

  Future<Team> createTeam({required String token, required String name}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/teams/');
    logger.d('TeamRepository: Creating team "$name" at $url');

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
        logger.i('TeamRepository: Team "$name" created successfully.');
        return Team.fromJson(body);
      } else {
        logger.e('TeamRepository: Failed to create team. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to create team. Server response: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('TeamRepository: Error creating team "$name": $e');
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
    logger.d('TeamRepository: Adding $role $userId to team $teamId at $url');
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
        logger.e('TeamRepository: Failed to add member. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to add member. Server response: ${response.body}',
        );
      }
      logger.i('TeamRepository: Member $userId added as $role to team $teamId.');
    } catch (e) {
      logger.e('TeamRepository: Error adding member $userId to team $teamId: $e');
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
    logger.d('TeamRepository: Removing $role $userId from team $teamId at $url');
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
        logger.e('TeamRepository: Failed to remove member. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to remove member. Server response: ${response.body}',
        );
      }
      logger.i('TeamRepository: Member $userId removed as $role from team $teamId.');
    } catch (e) {
      logger.e('TeamRepository: Error removing member $userId from team $teamId: $e');
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
    logger.d('TeamRepository: Creating and adding player $username to team $teamId at $url');
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
        logger.i('TeamRepository: Player $username created and added to team $teamId.');
        return User.fromJson(json.decode(response.body));
      } else {
        logger.e('TeamRepository: Failed to add player. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to add player. Server response: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('TeamRepository: Error adding player $username to team $teamId: $e');
      throw Exception('An error occurred while adding a player: $e');
    }
  }

  Future<User> createAndAddCoach({
    required String token,
    required int teamId,
    required String email,
    required String username,
    String? firstName,
    String? lastName,
    required String coachType,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/teams/$teamId/create_and_add_coach/',
    );
    logger.d('TeamRepository: Creating and adding coach $username to team $teamId at $url');
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
          'coach_type': coachType,
        }),
      );
      if (response.statusCode == 201) {
        logger.i('TeamRepository: Coach $username created and added to team $teamId.');
        return User.fromJson(json.decode(response.body));
      } else {
        logger.e('TeamRepository: Failed to add coach. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to add coach. Server response: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('TeamRepository: Error adding coach $username to team $teamId: $e');
      throw Exception('An error occurred while adding a coach: $e');
    }
  }

  Future<User> createAndAddStaff({
    required String token,
    required int teamId,
    required String username,
    required String email,
    String? firstName,
    String? lastName,
    required String staffType,
  }) async {
    try {
      logger.i('TeamRepository: Creating staff member $username for team $teamId.');
      
      // First, create the user
      final createUrl = Uri.parse('${ApiClient.baseUrl}/users/register/');
      final createResponse = await _client.post(
        createUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': 'TempPassword123!', // Temporary password
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
          'role': 'STAFF',
          'staff_type': staffType,
        }),
      );
      
      if (createResponse.statusCode == 201) {
        final userData = json.decode(createResponse.body);
        final userId = userData['id'];
        
        // Now add the staff member to the team
        final addUrl = Uri.parse('${ApiClient.baseUrl}/teams/$teamId/add_member/');
        final addResponse = await _client.post(
          addUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'user_id': userId,
            'role': 'staff',
            'staff_type': staffType,
          }),
        );
        
        if (addResponse.statusCode == 200) {
          logger.i('TeamRepository: Staff member $username created and added to team $teamId.');
          return User.fromJson(userData);
        } else {
          logger.e('TeamRepository: Failed to add staff to team. Status: ${addResponse.statusCode}, Body: ${addResponse.body}');
          throw Exception('Failed to add staff to team. Server response: ${addResponse.body}');
        }
      } else {
        logger.e('TeamRepository: Failed to create staff member. Status: ${createResponse.statusCode}, Body: ${createResponse.body}');
        throw Exception('Failed to create staff member. Server response: ${createResponse.body}');
      }
    } catch (e) {
      logger.e('TeamRepository: Error creating staff member $username for team $teamId: $e');
      throw Exception('An error occurred while creating a staff member: $e');
    }
  }
}
