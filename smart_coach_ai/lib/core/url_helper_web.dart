// Web implementation — only compiled on Flutter Web (dart.library.html available).
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Returns `window.location.origin` from the browser.
/// e.g. "http://localhost:5173" or "https://myapp.com"
String getWebOrigin() {
  return html.window.location.origin;
}
