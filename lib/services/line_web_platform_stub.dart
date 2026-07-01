/// No-op stub used on non-web platforms — LINE web login only ever runs
/// behind a `kIsWeb` check, so these bodies are never reached there.
class LineWebPlatform {
  static bool get hasPendingCallback => false;
  static Map<String, String>? readCallbackParams() => null;
  static void clearCallbackParamsFromUrl() {}
  static void redirect(String url) {}
  static String get currentOrigin => '';
  static Future<void> stashSessionForHandoff(String sessionJson) async {}
  static Future<String?> readAndClearHandoffSession() async => null;
}
