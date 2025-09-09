import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/password_change_model.dart';
import '../../../../core/api/api_client.dart';

class PasswordRepository {
  final http.Client _client;

  PasswordRepository(this._client);

  Future<void> changePassword(PasswordChangeRequest request, String token) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiClient.baseUrl}/auth/users/change_password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        final errors = json.decode(response.body);
        if (errors is Map<String, dynamic>) {
          throw PasswordChangeException(errors);
        }
        throw Exception('Failed to change password: ${response.body}');
      } else {
        throw Exception('Failed to change password: ${response.statusCode}');
      }
    } catch (e) {
      if (e is PasswordChangeException) {
        rethrow;
      }
      throw Exception('Failed to change password: $e');
    }
  }

  Future<String> resetPassword(int userId, PasswordResetRequest request, String token) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiClient.baseUrl}/auth/users/$userId/reset_password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['new_password'] ?? 'fortaleza2025';
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to reset this user\'s password');
      } else {
        throw Exception('Failed to reset password: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }
}

class PasswordChangeException implements Exception {
  final Map<String, dynamic> errors;

  PasswordChangeException(this.errors);

  @override
  String toString() {
    final errorMessages = <String>[];
    
    errors.forEach((key, value) {
      if (value is List) {
        errorMessages.addAll(value.map((e) => e.toString()));
      } else {
        errorMessages.add(value.toString());
      }
    });
    
    return errorMessages.join('\n');
  }
}
