// lib/features/authentication/data/repositories/user_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  final http.Client _client = http.Client();

  Future<List<User>> searchUsers({
    required String token,
    required String query,
  }) async {
    if (query.isEmpty) return []; // Don't search for nothing
    
    final url = Uri.parse('${ApiClient.baseUrl}/auth/search/').replace(
      queryParameters: {'search': query},
    );

    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => User.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search users.');
      }
    } catch (e) {
      throw Exception('An error occurred during user search: $e');
    }
  }
}