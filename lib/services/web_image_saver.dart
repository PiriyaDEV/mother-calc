// Conditional import facade for web image download/share.
// On web: uses dart:js_interop to trigger browser download or Web Share API.
// On mobile/desktop: stub (never called — caller guards with kIsWeb).
export 'web_image_saver_stub.dart'
    if (dart.library.js_interop) 'web_image_saver_web.dart'
    show downloadImageOnWeb, shareImageOnWeb, webShareSupported, downloadPdfOnWeb;
