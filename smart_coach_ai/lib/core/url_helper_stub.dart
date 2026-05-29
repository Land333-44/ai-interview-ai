// Stub implementation for non-web platforms (mobile, desktop).
// On these platforms we don't have dart:html, so we return an empty string.
// The caller (AppUrlHelper) handles this gracefully.

/// Returns an empty string on non-web platforms.
String getWebOrigin() => '';
