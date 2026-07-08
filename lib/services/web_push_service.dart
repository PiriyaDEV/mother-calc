// Conditional import facade — web implementation uses the Web Push API (VAPID);
// mobile/desktop stub is a no-op so the rest of the codebase compiles unchanged.
export 'web_push_service_stub.dart'
    if (dart.library.js_interop) 'web_push_service_web.dart';
