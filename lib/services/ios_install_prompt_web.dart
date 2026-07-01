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
    final isStandalone = _navigatorStandalone?.toDart ?? false;
    return isIos && !isStandalone;
  } catch (_) {
    return false;
  }
}
