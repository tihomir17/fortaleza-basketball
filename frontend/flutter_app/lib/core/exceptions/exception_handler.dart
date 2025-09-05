// lib/core/exceptions/exception_handler.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'app_exceptions.dart';

/// Utility class for handling and converting various exceptions
class ExceptionHandler {
  /// Convert HTTP response to appropriate exception
  static AppException handleHttpResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;
    
    try {
      // Try to parse error response from backend
      final errorData = _parseErrorResponse(body);
      final message = errorData['message'] ?? 'An error occurred';
      final code = errorData['code'];
      final details = errorData['details'];
      
      switch (statusCode) {
        case 400:
          return ValidationException(
            message: message,
            code: code,
            details: details,
          );
        case 401:
          return AuthenticationException(
            message: message,
            code: code,
            details: details,
          );
        case 403:
          return AuthorizationException(
            message: message,
            code: code,
            details: details,
          );
        case 404:
          return ServerException(
            message: 'Resource not found',
            code: 'not_found',
            details: details,
          );
        case 429:
          return ServerException(
            message: 'Too many requests. Please try again later.',
            code: 'rate_limit_exceeded',
            details: details,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          return ServerException(
            message: message,
            code: code,
            details: details,
          );
        default:
          return ServerException(
            message: message,
            code: code,
            details: details,
          );
      }
    } catch (e) {
      // If parsing fails, return generic server exception
      return ServerException(
        message: 'Server error (${statusCode})',
        code: 'server_error',
        details: {'status_code': statusCode, 'body': body},
      );
    }
  }
  
  /// Handle network-related exceptions
  static AppException handleNetworkException(dynamic exception) {
    if (exception is SocketException) {
      return NetworkException(
        message: 'No internet connection. Please check your network settings.',
        code: 'no_internet',
        details: {'exception': exception.toString()},
      );
    } else if (exception is HttpException) {
      return NetworkException(
        message: 'Network error occurred',
        code: 'http_exception',
        details: {'exception': exception.toString()},
      );
    } else if (exception is FormatException) {
      return NetworkException(
        message: 'Invalid response format from server',
        code: 'format_exception',
        details: {'exception': exception.toString()},
      );
    } else {
      return NetworkException(
        message: 'Network error occurred',
        code: 'network_error',
        details: {'exception': exception.toString()},
      );
    }
  }
  
  /// Handle general exceptions
  static AppException handleException(dynamic exception) {
    if (exception is AppException) {
      return exception;
    } else if (exception is SocketException || 
               exception is HttpException || 
               exception is FormatException) {
      return handleNetworkException(exception);
    } else {
      return UnknownException(
        message: 'An unexpected error occurred',
        code: 'unknown_error',
        details: {'exception': exception.toString()},
      );
    }
  }
  
  /// Parse error response from backend
  static Map<String, dynamic> _parseErrorResponse(String body) {
    try {
      // Try to parse as JSON
      final Map<String, dynamic> parsed = 
          jsonDecode(body) as Map<String, dynamic>;
      
      // Check if it's our custom error format
      if (parsed.containsKey('error')) {
        final error = parsed['error'] as Map<String, dynamic>;
        return {
          'message': error['message'] ?? 'An error occurred',
          'code': error['code'],
          'details': error['details'] ?? {},
        };
      }
      
      // Check for standard DRF error format
      if (parsed.containsKey('detail')) {
        return {
          'message': parsed['detail'] as String,
          'code': 'api_error',
          'details': parsed,
        };
      }
      
      // Return the whole response as details
      return {
        'message': 'An error occurred',
        'code': 'api_error',
        'details': parsed,
      };
    } catch (e) {
      // If JSON parsing fails, return the raw body
      return {
        'message': body.isNotEmpty ? body : 'An error occurred',
        'code': 'parse_error',
        'details': {'raw_body': body},
      };
    }
  }
  
  /// Log exception for debugging
  static void logException(AppException exception, {String? context}) {
    if (kDebugMode) {
      print('Exception${context != null ? ' in $context' : ''}: ${exception.toString()}');
      if (exception.details != null) {
        print('Details: ${exception.details}');
      }
    }
  }
}

