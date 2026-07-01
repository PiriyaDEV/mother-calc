// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Cookie name used to hand a Supabase session from a plain Safari tab
/// (where LINE's OAuth redirect lands) back to the installed home-screen
/// PWA instance (which shares the same origin's cookies but NOT its
/// localStorage/IndexedDB).
const _kSessionCookieName = 'sb_pwa_session';

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

  // ── Cookie-based PWA↔Safari session handoff ──────────────────────────────
  //
  // iOS keeps localStorage/IndexedDB partitioned between a standalone PWA
  // and plain Safari even when they share the same origin.  Cookies are the
  // only storage that crosses that boundary, so we use a short-lived cookie
  // to carry the Supabase session JSON from the Safari tab (where LINE's
  // OAuth redirect always lands) back to the PWA instance.

  /// Writes [sessionJson] into a same-origin cookie that the PWA can read
  /// when it resumes.  The cookie expires in 5 minutes — just long enough
  /// for the user to switch back to the app; after that it's useless anyway
  /// because the PWA will have already consumed it.
  static void writePwaSessionCookie(String sessionJson) {
    try {
      // URI-encode so commas/semicolons inside the JSON don't break the
      // cookie header.
      final encoded = Uri.encodeComponent(sessionJson);
      // Max-Age=300 → 5 minutes.  SameSite=Lax is the safe default for
      // same-origin navigations; Secure is set automatically by the browser
      // when the page is served over HTTPS.
      html.document.cookie =
          '$_kSessionCookieName=$encoded; Path=/; SameSite=Lax; Max-Age=300';
    } catch (_) {}
  }

  /// Returns the session JSON previously written by [writePwaSessionCookie],
  /// or null if the cookie is absent or expired.
  static String? readPwaSessionCookie() {
    try {
      final cookies = html.document.cookie ?? '';
      for (final part in cookies.split(';')) {
        final kv = part.trim().split('=');
        if (kv.length >= 2 && kv[0].trim() == _kSessionCookieName) {
          // Re-join in case the value itself contained '=' (base64 padding).
          final raw = kv.sublist(1).join('=').trim();
          return Uri.decodeComponent(raw);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Deletes the handoff cookie so it can't be replayed.
  static void clearPwaSessionCookie() {
    try {
      html.document.cookie =
          '$_kSessionCookieName=; Path=/; SameSite=Lax; Max-Age=0';
    } catch (_) {}
  }
}
