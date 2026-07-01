// Conditionally picks the web implementation (dart:html) when compiling for
// web, and a no-op stub everywhere else — so mobile builds never try to
// compile dart:html.
export 'line_web_platform_stub.dart'
    if (dart.library.html) 'line_web_platform_web.dart';
