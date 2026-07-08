// Stub for non-web platforms — these functions are never called on mobile
// because the caller guards with kIsWeb.

Future<bool> downloadImageOnWeb(
  List<int> bytes,
  String filename,
) async =>
    false;

Future<bool> shareImageOnWeb(
  List<int> bytes,
  String filename,
  String title,
) async =>
    false;

bool get webShareSupported => false;
