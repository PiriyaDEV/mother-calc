// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:math';
import 'dart:ui_web' as ui_web;

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';

/// Called with (idToken, rawNonce) once Google Identity Services returns a
/// signed credential for the account the user picked.
typedef GoogleCredentialCallback = void Function(String idToken, String rawNonce);

bool _gisScriptLoading = false;
bool _gisScriptLoaded = false;
final _onGisReady = <void Function()>[];

void _ensureGisScriptLoaded(void Function() onReady) {
  if (_gisScriptLoaded) {
    onReady();
    return;
  }
  _onGisReady.add(onReady);
  if (_gisScriptLoading) return;
  _gisScriptLoading = true;
  final script = html.ScriptElement()
    ..src = 'https://accounts.google.com/gsi/client'
    ..async = true;
  script.onLoad.listen((_) {
    _gisScriptLoaded = true;
    for (final cb in _onGisReady) {
      cb();
    }
    _onGisReady.clear();
  });
  html.document.head!.append(script);
}

String _generateRawNonce() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes);
}

String _hashNonce(String raw) => sha256.convert(utf8.encode(raw)).toString();

int _viewCounter = 0;

/// Renders Google Identity Services' own "Sign in with Google" button,
/// driving `google.accounts.id` directly instead of through
/// `google_sign_in_web`.
///
/// `google_sign_in_web` (0.12.4) hardcodes `use_fedcm_for_prompt: true` and
/// has no `nonce` field at all. When a browser uses the FedCM path, Google
/// embeds a `nonce` claim in the returned ID token regardless — and
/// Supabase's `signInWithIdToken` rejects the token unless a matching nonce
/// is supplied ("Passed nonce and nonce in id_token should either both
/// exist or not"). Driving GIS ourselves lets us generate that nonce and
/// pass the same value to both Google and Supabase.
Widget renderGoogleSignInButton({
  required String clientId,
  required GoogleCredentialCallback onCredential,
  double minimumWidth = 320,
}) {
  final viewType = 'gsi_login_button_${_viewCounter++}';
  final rawNonce = _generateRawNonce();
  final hashedNonce = _hashNonce(rawNonce);

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final container = html.DivElement()
      ..style.width = '100%'
      ..style.display = 'flex'
      ..style.justifyContent = 'center';

    _ensureGisScriptLoaded(() {
      final id = js.context['google']['accounts']['id'] as js.JsObject;

      id.callMethod('initialize', [
        js.JsObject.jsify({
          'client_id': clientId,
          'nonce': hashedNonce,
          'use_fedcm_for_prompt': true,
          'callback': js.allowInterop((js.JsObject response) {
            final credential = response['credential'] as String?;
            if (credential != null) onCredential(credential, rawNonce);
          }),
        }),
      ]);

      id.callMethod('renderButton', [
        container,
        js.JsObject.jsify({
          'theme': 'outline',
          'size': 'large',
          'text': 'signin_with',
          'shape': 'pill',
          'width': minimumWidth,
        }),
      ]);
    });

    return container;
  });

  return SizedBox(
    width: minimumWidth,
    height: 44,
    child: HtmlElementView(viewType: viewType),
  );
}
