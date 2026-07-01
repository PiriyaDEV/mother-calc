// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// localStorage key used to persist the loginId across the LINE OAuth
/// redirect round-trip.  The PWA writes this before navigating to LINE
/// and reads it back when polling for the completed session.
const _kLoginIdKey = 'line_login_id';

/// Browser-backed implementation.
class LineWebPlatform {
  static bool get hasPendingCallback {
    try {
      final params = Uri.base.queryParameters;
      return params.containsKey('code') && params.containsKey('state');
    } catch (_) {
      return false;
    }
  }

  static Map<String, String>? readCallbackParams() {
    try {
      final params = Uri.base.queryParameters;
      final code = params['code'];
      final state = params['state'];
      if (code == null || state == null) return null;
      return {'code': code, 'state': state};
    } catch (_) {
      return null;
    }
  }

  /// Strips ?code&state from the address bar so a page refresh doesn't
  /// try to redeem the same (now-consumed) authorization code again.
  static void clearCallbackParamsFromUrl() {
    try {
      final cleanUrl = Uri.base.replace(queryParameters: {}).toString();
      html.window.history.replaceState(null, '', cleanUrl);
    } catch (_) {}
  }

  static void redirect(String url) {
    try {
      html.window.location.href = url;
    } catch (_) {}
  }

  /// Use Uri.base (pure Dart) instead of html.window.location.origin
  /// to avoid SecurityError in certain browser contexts.
  static String get currentOrigin {
    try {
      final base = Uri.base;
      return '${base.scheme}://${base.host}${base.hasPort && base.port != 80 && base.port != 443 ? ':${base.port}' : ''}';
    } catch (_) {
      return '';
    }
  }

  // ── localStorage-based loginId for PWA polling handoff ───────────────────
  //
  // The PWA generates a random loginId before redirecting to LINE and saves
  // it in its own localStorage.  When LINE's callback lands in a plain Safari
  // tab, the backend stores the completed session keyed by loginId.  The PWA
  // (still open in the background, or relaunched cold) reads the loginId from
  // its own localStorage and polls the backend until the session appears.
  // No cross-context storage sharing is needed — each context only reads its
  // own localStorage.

  /// Saves [loginId] to localStorage so it survives the LINE redirect.
  static void saveLoginId(String loginId) {
    try {
      html.window.localStorage[_kLoginIdKey] = loginId;
    } catch (_) {}
  }

  /// Returns the loginId saved by [saveLoginId], or null if absent.
  static String? readLoginId() {
    try {
      final v = html.window.localStorage[_kLoginIdKey];
      return (v != null && v.isNotEmpty) ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// Removes the loginId from localStorage (call after session is recovered).
  static void clearLoginId() {
    try {
      html.window.localStorage.remove(_kLoginIdKey);
    } catch (_) {}
  }
}
