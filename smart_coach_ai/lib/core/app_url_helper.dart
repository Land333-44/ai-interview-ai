import 'package:flutter/foundation.dart';

// Conditionally import dart:html only on web.
// On non-web platforms, the stub is used instead (returns empty string).
import 'url_helper_stub.dart'
    if (dart.library.html) 'url_helper_web.dart';

/// Provides the correct base URL automatically.
///
/// • **Flutter Web**  → reads `window.location.origin`
///   e.g. `http://localhost:5173` or `https://myapp.com`
/// • **Mobile / Desktop** → returns an empty string (OAuth / deep-link
///   is handled differently on those platforms and does not need a web URL).
///
/// Usage:
/// ```dart
/// final url = '${AppUrlHelper.origin}/reset-password';
/// ```
class AppUrlHelper {
  AppUrlHelper._();

  /// The current page's origin (scheme + host + port), auto-detected.
  /// Returns empty string on non-web platforms.
  static String get origin {
    final raw = getWebOrigin(); // implemented per-platform
    if (kDebugMode && raw.isNotEmpty) {
      debugPrint('[AppUrlHelper] origin = $raw');
    }
    return raw;
  }

  /// Full redirect URL for **email verification**.
  /// e.g. `http://localhost:5173/verify-email`
  static String get emailVerificationUrl => '$origin/verify-email';

  /// Full redirect URL for **password recovery**.
  /// e.g. `http://localhost:5173/reset-password`
  static String get passwordRecoveryUrl => '$origin/reset-password';
}
