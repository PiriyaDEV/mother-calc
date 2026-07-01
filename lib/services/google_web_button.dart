// Conditionally picks the web implementation (which renders Google Identity
// Services' own button) when compiling for web, and a no-op stub everywhere
// else — so mobile builds never try to compile google_sign_in_web.
export 'google_web_button_stub.dart'
    if (dart.library.html) 'google_web_button_web.dart';
