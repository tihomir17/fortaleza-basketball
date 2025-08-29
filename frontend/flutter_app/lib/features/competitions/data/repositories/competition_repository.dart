// lib/features/competitions/data/repositories/competition_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/competition_model.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class CompetitionRepository {
  final http.Client _client = http.Client();

  Future<List<Competition>> getAllCompetitions(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/competitions/');
    logger.d('CompetitionRepository: Fetching all competitions at $url');
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        logger.i('CompetitionRepository: Loaded ${body.length} competitions.');
        return body.map((json) => Competition.fromJson(json)).toList();
      } else {
        logger.e('CompetitionRepository: Failed to load competitions. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load competitions');
      }
    } catch (e) {
      logger.e('CompetitionRepository: Error fetching competitions: $e');
      throw Exception('Error fetching competitions: $e');
    }
  }
}
