import 'dart:html' as html;

/// Browser-backed implementation. sessionStorage survives the full-page
/// redirect to LINE and back (same tab, same origin) but not a new tab.
class LineWebPlatform {
  static bool get hasPendingCallback {
    final params = Uri.base.queryParameters;
    return params.containsKey('code') && params.containsKey('state');
  }

  static Map<String, String>? readCallbackParams() {
    final params = Uri.base.queryParameters;
    final code = params['code'];
    final state = params['state'];
    if (code == null || state == null) return null;
    return {'code': code, 'state': state};
  }

  /// Strips ?code&state from the address bar so a page refresh doesn't
  /// try to redeem the same (now-consumed) authorization code again.
  static void clearCallbackParamsFromUrl() {
    final cleanUrl = Uri.base.replace(queryParameters: {}).toString();
    html.window.history.replaceState(null, '', cleanUrl);
  }

  static void saveVerifier(String state, String verifier) {
    html.window.sessionStorage['line_pkce_$state'] = verifier;
  }

  static String? consumeVerifier(String state) {
    final key = 'line_pkce_$state';
    final value = html.window.sessionStorage[key];
    html.window.sessionStorage.remove(key);
    return value;
  }

  static void redirect(String url) {
    html.window.location.href = url;
  }

  static String get currentOrigin => html.window.location.origin;
}
