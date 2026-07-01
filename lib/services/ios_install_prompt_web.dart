// Web implementation — detects iOS Safari not in standalone (PWA) mode.
import 'dart:js_interop';

@JS('navigator.standalone')
external JSBoolean? get _navigatorStandalone;

@JS('navigator.userAgent')
external JSString get _navigatorUserAgent;

bool get isIosNotStandalone {
  try {
    final ua = _navigatorUserAgent.toDart;
    final isIos = ua.contains('iPhone') || ua.contains('iPad') || ua.contains('iPod');
    return isIos && !isStandalone;
  } catch (_) {
    return false;
  }
}

/// True when running as an installed home-screen web app (iOS Safari's
/// `navigator.standalone`). Used to detect the case where a LINE login
/// redirect landed in a plain Safari tab instead of the installed PWA —
/// iOS has no mechanism to hand an external OAuth redirect back to a
/// standalone PWA instance, so it always opens Safari.
bool get isStandalone {
  try {
    return _navigatorStandalone?.toDart ?? false;
  } catch (_) {
    return false;
  }
}
