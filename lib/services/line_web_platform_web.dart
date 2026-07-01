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
}
