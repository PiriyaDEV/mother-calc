// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Browser-backed implementation.
class LineWebPlatform {
  // iOS gives a plain Safari tab (not the installed home-screen PWA) the
  // ?code&state redirect from LINE, and never hands it back to the PWA —
  // see docs/FIXES.md. localStorage/cookies are NOT shared between Safari
  // and a standalone PWA for the same origin on iOS, but the Cache Storage
  // API *is* shared between them, so it's used here purely as a scratch
  // key-value store to hand the completed session from one to the other.
  static const _handoffCacheName = 'kidtang-line-login-handoff';
  static const _handoffKey = '/__line_login_session';

  /// Stashes the just-completed Supabase session JSON so the installed PWA
  /// instance can pick it up once the user switches back to it.
  static Future<void> stashSessionForHandoff(String sessionJson) async {
    try {
      final cache = await web.window.caches.open(_handoffCacheName).toDart;
      await cache.put(_handoffKey.toJS, web.Response(sessionJson.toJS)).toDart;
    } catch (_) {}
  }

  /// Reads back a session stashed by [stashSessionForHandoff], if any, and
  /// deletes it — single-use, so a later launch doesn't replay a stale one.
  static Future<String?> readAndClearHandoffSession() async {
    try {
      final cache = await web.window.caches.open(_handoffCacheName).toDart;
      final response = await cache.match(_handoffKey.toJS).toDart;
      if (response == null) return null;
      final text = await response.text().toDart;
      await cache.delete(_handoffKey.toJS).toDart;
      return text.toDart;
    } catch (_) {
      return null;
    }
  }
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
