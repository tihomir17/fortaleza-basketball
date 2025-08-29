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
      final status = response.statusCode;
      final bodyText = response.body;
      logger.d('CompetitionRepository: Response status=$status, body=${bodyText.length > 800 ? '${bodyText.substring(0, 800)}...<truncated>' : bodyText}');
      if (status == 200) {
        final dynamic decoded = json.decode(bodyText);
        List<dynamic> items;
        String fromKey = '<top-level>';
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['results'] is List) {
            items = decoded['results'] as List<dynamic>;
            fromKey = 'results';
          } else if (decoded['competitions'] is List) {
            items = decoded['competitions'] as List<dynamic>;
            fromKey = 'competitions';
          } else {
            final listEntry = decoded.entries.firstWhere(
              (e) => e.value is List,
              orElse: () => const MapEntry<String, dynamic>('#none', null),
            );
            if (listEntry.key != '#none') {
              items = (listEntry.value as List).cast<dynamic>();
              fromKey = listEntry.key;
              logger.w('CompetitionRepository: Using fallback list at key "$fromKey" with ${items.length} items. Keys=${decoded.keys.toList()}');
            } else {
              logger.e('CompetitionRepository: Unexpected JSON shape. Keys=${decoded.keys.toList()}');
              throw Exception('Unexpected competitions payload shape.');
            }
          }
        } else {
          logger.e('CompetitionRepository: Unexpected JSON root type: ${decoded.runtimeType}');
          throw Exception('Unexpected competitions payload type: ${decoded.runtimeType}');
        }
        logger.d('CompetitionRepository: Parsed List from "$fromKey" with ${items.length} items.');
        final list = items.map((json) => Competition.fromJson(json)).toList();
        logger.i('CompetitionRepository: Loaded ${list.length} competitions.');
        return list;
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
