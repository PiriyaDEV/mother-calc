// Web implementation — downloads PNG bytes via a temporary <a> element,
// or shares via the Web Share API (navigator.share) on iOS PWA / mobile browsers.
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

// ── JS bindings ───────────────────────────────────────────────────────────────

@JS('window._kidtangImageSaver.download')
external void _jsDownload(JSString dataUrl, JSString filename);

@JS('window._kidtangImageSaver.share')
external JSPromise<JSBoolean> _jsShare(
    JSString dataUrl, JSString filename, JSString title);

@JS('window._kidtangImageSaver.canShare')
external JSBoolean _jsCanShare();

// ── Public API ────────────────────────────────────────────────────────────────

/// Downloads PNG bytes as a file in the browser.
/// Uses a JS helper injected in web/index.html.
Future<bool> downloadImageOnWeb(
  List<int> bytes,
  String filename,
) async {
  try {
    final base64 = _bytesToBase64(bytes);
    final dataUrl = 'data:image/png;base64,$base64';
    _jsDownload(dataUrl.toJS, filename.toJS);
    return true;
  } catch (e) {
    debugPrint('[WebImageSaver.downloadImageOnWeb]: $e');
    return false;
  }
}

/// Shares PNG bytes via the Web Share API (navigator.share).
/// Falls back to download if share is not supported.
Future<bool> shareImageOnWeb(
  List<int> bytes,
  String filename,
  String title,
) async {
  try {
    final base64 = _bytesToBase64(bytes);
    final dataUrl = 'data:image/png;base64,$base64';
    final result = await _jsShare(dataUrl.toJS, filename.toJS, title.toJS).toDart;
    return result.toDart;
  } catch (e) {
    debugPrint('[WebImageSaver.shareImageOnWeb]: $e');
    // Fallback to download
    return downloadImageOnWeb(bytes, filename);
  }
}

/// Downloads PDF bytes as a .pdf file in the browser.
/// Uses a data URL with application/pdf MIME type.
bool downloadPdfOnWeb(List<int> bytes, String filename) {
  try {
    final base64 = _bytesToBase64(bytes);
    final dataUrl = 'data:application/pdf;base64,$base64';
    _jsDownload(dataUrl.toJS, filename.toJS);
    return true;
  } catch (e) {
    debugPrint('[WebImageSaver.downloadPdfOnWeb]: $e');
    return false;
  }
}

/// Whether the Web Share API is available (true on iOS PWA / mobile browsers).
bool get webShareSupported {
  try {
    return _jsCanShare().toDart;
  } catch (_) {
    return false;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _bytesToBase64(List<int> bytes) {
  // dart:convert base64 encode
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final buf = StringBuffer();
  int i = 0;
  while (i < bytes.length) {
    final b0 = bytes[i++];
    final b1 = i < bytes.length ? bytes[i++] : 0;
    final b2 = i < bytes.length ? bytes[i++] : 0;
    buf.write(chars[(b0 >> 2) & 0x3F]);
    buf.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
    buf.write(chars[((b1 << 2) | (b2 >> 6)) & 0x3F]);
    buf.write(chars[b2 & 0x3F]);
  }
  final result = buf.toString();
  // Add padding
  final pad = bytes.length % 3;
  if (pad == 1) {
    return '${result.substring(0, result.length - 2)}==';
  } else if (pad == 2) {
    return '${result.substring(0, result.length - 1)}=';
  }
  return result;
}
