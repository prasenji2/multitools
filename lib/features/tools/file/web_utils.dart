import 'dart:html' as html;
import 'dart:typed_data';

/// Web-specific utilities for file operations
class WebUtils {
  /// Downloads a file in the browser
  static void downloadFile(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    
    // Trigger download
    anchor.click();
    
    // Clean up
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
