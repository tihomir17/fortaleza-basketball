// lib/core/api/api_client.dart
class ApiClient {
  // For testing with a local Django server on a mobile emulator,
  // use 10.0.2.2 for Android and 127.0.0.1 for iOS/web.
  static const String baseUrl = "http://127.0.0.1:8000/api";
  // static const String baseUrl = "http://10.0.2.2:8000/api";
}