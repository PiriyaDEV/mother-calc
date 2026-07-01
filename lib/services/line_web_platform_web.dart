// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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

  // ── LINE web login iOS PWA handoff ──────────────────────────────
  // iOS gives a LINE web login's OAuth redirect to a plain Safari tab
  // instead of handing it back to the installed home-screen PWA, and
  // shares neither localStorage nor Cache Storage reliably between the two
  // contexts for the same origin — so the completed session can't be
  // handed off through browser storage at all (see AuthProvider, which
  // hands it off through the server instead via a pairing_id).
  //
  // This pairing_id, however, only ever needs to be read back by *this
  // same* browsing context after being relaunched — that's ordinary
  // same-origin localStorage persistence across a process kill, which iOS
  // does support; it's only sharing storage *between two different
  // contexts* (Safari tab vs. standalone PWA) that iOS doesn't support.
  static const _pairingIdKey = 'kidtang_line_pairing_id';

  static void savePendingPairingId(String pairingId) {
    try {
      html.window.localStorage[_pairingIdKey] = pairingId;
    } catch (_) {}
  }

  static String? readPendingPairingId() {
    try {
      return html.window.localStorage[_pairingIdKey];
    } catch (_) {
      return null;
    }
  }

  static void clearPendingPairingId() {
    try {
      html.window.localStorage.remove(_pairingIdKey);
    } catch (_) {}
  }
}
