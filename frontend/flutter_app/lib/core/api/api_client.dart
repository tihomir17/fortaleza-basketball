// lib/core/api/api_client.dart
class ApiClient {
  // Configure base URL at build time:
  // flutter run --dart-define=API_BASE_URL=https://your.api/api
  // Defaults to localhost for development.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
}