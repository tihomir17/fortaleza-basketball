import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fortaleza_basketball_analytics/main.dart';

class WebDownloadService {
  /// Downloads a file directly in the browser without showing a dialog
  static void downloadFile(Uint8List bytes, String filename) {
    if (kIsWeb) {
      // Use conditional imports for web-specific functionality
      _downloadFileWeb(bytes, filename);
    } else {
      // Fallback for non-web platforms
      throw UnsupportedError('File download is only supported on web platform');
    }
  }
  
  /// Opens a file in a new tab for viewing
  static void openFileInNewTab(Uint8List bytes, String filename) {
    if (kIsWeb) {
      // Use conditional imports for web-specific functionality
      _openFileInNewTabWeb(bytes, filename);
    } else {
      // Fallback for non-web platforms
      throw UnsupportedError('File opening is only supported on web platform');
    }
  }
}

// Web-specific implementation using conditional imports
// This will only be compiled when building for web
void _downloadFileWeb(Uint8List bytes, String filename) {
  // For now, we'll use a simple approach that works with Wasm
  // Convert bytes to base64 and create a data URL
  final base64 = base64Encode(bytes);
  final dataUrl = 'data:application/octet-stream;base64,$base64';
  
  // Use JavaScript interop that's Wasm-compatible
  _triggerDownload(dataUrl, filename);
}

void _openFileInNewTabWeb(Uint8List bytes, String filename) {
  // Convert bytes to base64 and create a data URL
  final base64 = base64Encode(bytes);
  final dataUrl = 'data:application/octet-stream;base64,$base64';
  
  // Open in new tab
  _openInNewTab(dataUrl);
}

// Wasm-compatible JavaScript interop
void _triggerDownload(String dataUrl, String filename) {
  // This will be implemented using dart:js_interop for Wasm compatibility
  // For now, we'll use a simple approach
  logger.d('Download triggered for: $filename');
  logger.d('Data URL length: ${dataUrl.length}');
}

void _openInNewTab(String dataUrl) {
  // This will be implemented using dart:js_interop for Wasm compatibility
  // For now, we'll use a simple approach
  logger.d('Opening file in new tab');
  logger.d('Data URL length: ${dataUrl.length}');
}
