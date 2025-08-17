// lib/features/competitions/data/repositories/competition_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/competition_model.dart';

class CompetitionRepository {
  final http.Client _client = http.Client();

  Future<List<Competition>> getAllCompetitions(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/competitions/');
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return body.map((json) => Competition.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load competitions');
      }
    } catch (e) {
      throw Exception('Error fetching competitions: $e');
    }
  }
}
