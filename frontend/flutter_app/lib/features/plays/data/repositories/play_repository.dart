// lib/features/plays/data/repositories/play_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/play_definition_model.dart';

class PlayRepository {
  final http.Client _client = http.Client();

  Future<List<PlayDefinition>> getPlaysForTeam({
    required String token,
    required int teamId,
  }) async {
    // Note the new nested URL structure
    final url = Uri.parse('${ApiClient.baseUrl}/teams/$teamId/plays/');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        final List<PlayDefinition> plays = body
            .map((dynamic item) => PlayDefinition.fromJson(item))
            .toList();
        return plays;
      } else {
        throw Exception('Failed to load playbook');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching the playbook: $e');
    }
  }
}