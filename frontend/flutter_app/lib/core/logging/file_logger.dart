import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class FileLogger {
  static final FileLogger _instance = FileLogger._internal();
  factory FileLogger() => _instance;
  FileLogger._internal();

  late Logger _logger;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (kDebugMode) {
      print('FileLogger: Starting initialization...');
    }

    if (_isInitialized) {
      if (kDebugMode) {
        print('FileLogger: Already initialized, skipping...');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('FileLogger: Setting up enhanced console logger...');
      }

      // Use enhanced console logging with better formatting
      _logger = Logger(
        level: Level.debug,
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 120,
          colors: true,
          printEmojis: false,
          printTime: true,
        ),
      );

      _isInitialized = true;

      if (kDebugMode) {
        print('=== FLUTTER DEBUG LOGGER ===');
        print('Enhanced console logging enabled');
        print('All logs will appear in the console with timestamps');
        print('==============================');
      }

      _logger.i('FileLogger initialized with enhanced console logging');

      if (kDebugMode) {
        print('FileLogger: Initialization completed successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize FileLogger: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      // Don't set _isInitialized to true if initialization failed
      _isInitialized = false;
    }
  }

  Logger get logger {
    if (!_isInitialized) {
      // Return a fallback logger that only writes to console
      return Logger(
        level: Level.debug,
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 80,
          colors: true,
          printEmojis: false,
          printTime: true,
        ),
      );
    }
    return _logger;
  }

  String get logFilePath {
    if (!_isInitialized) {
      return 'Logger not initialized yet';
    }
    return 'Enhanced console logging (no file)';
  }

  bool get isInitialized => _isInitialized;

  Future<void> forceReinitialize() async {
    if (kDebugMode) {
      print('FileLogger: Force reinitializing...');
    }
    _isInitialized = false;
    await initialize();
  }

  Future<void> testFileWriting() async {
    if (kDebugMode) {
      print('FileLogger: File writing not available - using console logging only');
    }
    _logger.i('Test log entry at ${DateTime.now()}');
  }

  Future<void> logPossessionData(
    String method,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized) return;

    _logger.i('=== POSSESSION DATA LOG ===');
    _logger.i('Method: $method');
    _logger.i('Data: ${data.toString()}');
    _logger.i('==========================');
  }

  Future<void> logApiResponse(
    String endpoint,
    int statusCode,
    String response,
  ) async {
    if (!_isInitialized) return;

    _logger.i('=== API RESPONSE LOG ===');
    _logger.i('Endpoint: $endpoint');
    _logger.i('Status: $statusCode');
    _logger.i('Response: $response');
    _logger.i('=======================');
  }

  Future<void> logError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
  ]) async {
    if (!_isInitialized) return;

    _logger.e('=== ERROR LOG ===');
    _logger.e('Context: $context');
    _logger.e('Error: $error');
    if (stackTrace != null) {
      _logger.e('StackTrace: $stackTrace');
    }
    _logger.e('================');
  }
}
