import 'dart:typed_data';

/// Stub implementation for non-web platforms
class WebUtils {
  /// Stub method for non-web platforms
  static void downloadFile(Uint8List bytes, String fileName) {
    // This method is not used on non-web platforms
    throw UnsupportedError('WebUtils.downloadFile is only supported on web platforms');
  }
}
