// Conditionally picks the web implementation on web, stub elsewhere.
export 'ios_install_prompt_stub.dart'
    if (dart.library.html) 'ios_install_prompt_web.dart';
