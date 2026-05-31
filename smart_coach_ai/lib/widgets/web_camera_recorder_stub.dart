import 'package:flutter/material.dart';

/// Stub implementation of WebCameraRecorder for non-web platforms.
/// This will never be executed on mobile, as the caller performs a `kIsWeb` check.
class WebCameraRecorder {
  static Future<({List<int> bytes, String name})?> show(
      BuildContext context) async {
    return null;
  }
}
