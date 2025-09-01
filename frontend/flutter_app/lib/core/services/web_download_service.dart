import 'dart:html' as html;
import 'dart:typed_data';
import 'package:js/js.dart';

@JS('URL.createObjectURL')
external String createObjectURL(html.Blob blob);

@JS('URL.revokeObjectURL')
external void revokeObjectURL(String url);

class WebDownloadService {
  /// Downloads a file directly in the browser without showing a dialog
  static void downloadFile(Uint8List bytes, String filename) {
    // Create a blob from the bytes
    final blob = html.Blob([bytes]);
    
    // Create a URL for the blob
    final url = createObjectURL(blob);
    
    // Create a download link
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    
    // Add to DOM, click, and remove
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    
    // Clean up the URL
    revokeObjectURL(url);
  }
  
  /// Opens a file in a new tab for viewing
  static void openFileInNewTab(Uint8List bytes, String filename) {
    // Create a blob from the bytes
    final blob = html.Blob([bytes]);
    
    // Create a URL for the blob
    final url = createObjectURL(blob);
    
    // Open in new tab
    html.window.open(url, '_blank');
    
    // Clean up the URL after a delay
    Future.delayed(const Duration(seconds: 5), () {
      revokeObjectURL(url);
    });
  }
}
