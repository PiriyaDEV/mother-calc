import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'line_web_platform.dart';

class LineWebProfile {
  final String userId;
  final String displayName;
  final String? pictureUrl;

  /// The pairing id generated in [LineWebAuthService.startLogin] and echoed
  /// back via `state` — used by AuthProvider to hand this session off to
  /// the originating browsing context (see get_line_login_handoff()) when
  /// this callback landed in a different one (e.g. iOS routed it to a
  /// plain Safari tab instead of back to the installed home-screen PWA).
  final String pairingId;

  LineWebProfile({
    required this.userId,
    required this.displayName,
    this.pictureUrl,
    required this.pairingId,
  });
}

/// LINE Login for Flutter web via OAuth2 Authorization Code + PKCE.
///
/// flutter_line_sdk has no web implementation, so this talks to LINE's
/// OAuth endpoints directly. PKCE (code_verifier/code_challenge) lets a
/// public client (a browser app) exchange the auth code for a token
/// without ever holding LINE_CHANNEL_SECRET client-side.
class LineWebAuthService {
  static const _authorizeUrl = 'https://access.line.me/oauth2/v2.1/authorize';
  static const _tokenUrl = 'https://api.line.me/oauth2/v2.1/token';
  static const _profileUrl = 'https://api.line.me/v2/profile';

  /// Redirects the whole page to LINE's login screen. On success this
  /// call never returns — the browser navigates away and the app reloads
  /// fresh when LINE redirects back to [LineWebPlatform.currentOrigin].
  static void startLogin(String channelId) {
    final origin = LineWebPlatform.currentOrigin;
    if (origin.isEmpty) {
      throw StateError(
          'LineWebPlatform.currentOrigin is empty — dart:html may not be available. '
          'Check that the web platform implementation is being used.');
    }

    final verifier = _randomToken();
    final challenge = _codeChallenge(verifier);
    // Generated unconditionally — we don't know until the callback lands
    // whether iOS routed it back to this same PWA instance or to a plain
    // Safari tab, so a pairing id is always available in case it's needed
    // to hand the session off (see AuthProvider._completeLineWebLogin).
    // Saved to *this* browsing context's own storage now, before
    // navigating away — read back later by the same context after being
    // relaunched, which is ordinary same-origin persistence, not a
    // cross-context storage share (iOS doesn't support that part).
    final pairingId = _randomToken();
    LineWebPlatform.savePendingPairingId(pairingId);

    final url = Uri.parse(_authorizeUrl).replace(queryParameters: {
      'response_type': 'code',
      'client_id': channelId,
      'redirect_uri': origin,
      // verifier + pairingId are packed into `state` — LINE echoes it back
      // verbatim on redirect, so completing login never depends on browser
      // storage surviving the round trip. That matters here: LINE hands
      // off to its native app for login, then returns via a fresh browser
      // tab/context — on iOS, when launched from an installed home-screen
      // PWA, that's plain Safari, a completely different storage partition
      // from the standalone PWA instance. `.` is safe as a delimiter since
      // both tokens are base64url (alphabet excludes `.`).
      'state': '$verifier.$pairingId',
      'scope': 'profile openid',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });
    LineWebPlatform.redirect(url.toString());
  }

  static bool get hasPendingCallback => LineWebPlatform.hasPendingCallback;

  /// See [LineWebPlatform.readPendingPairingId].
  static String? readPendingPairingId() => LineWebPlatform.readPendingPairingId();

  /// See [LineWebPlatform.clearPendingPairingId].
  static void clearPendingPairingId() => LineWebPlatform.clearPendingPairingId();

  /// Completes the flow after LINE redirects back with ?code&state.
  /// Throws on any failure (missing callback params, LINE API error).
  static Future<LineWebProfile> completeLogin(String channelId) async {
    final params = LineWebPlatform.readCallbackParams();
    if (params == null) {
      throw StateError('No LINE callback params present');
    }
    // Clear immediately so a page refresh can't replay the same code.
    LineWebPlatform.clearCallbackParamsFromUrl();

    final stateParts = params['state']!.split('.');
    final verifier = stateParts[0];
    final pairingId = stateParts.length > 1 ? stateParts[1] : '';

    final tokenResponse = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': params['code']!,
        'redirect_uri': LineWebPlatform.currentOrigin,
        'client_id': channelId,
        'code_verifier': verifier,
      },
    );
    if (tokenResponse.statusCode != 200) {
      throw Exception('LINE token exchange failed: ${tokenResponse.body}');
    }
    final accessToken = (jsonDecode(tokenResponse.body)
        as Map<String, dynamic>)['access_token'] as String;

    final profileResponse = await http.get(
      Uri.parse(_profileUrl),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (profileResponse.statusCode != 200) {
      throw Exception('LINE profile fetch failed: ${profileResponse.body}');
    }
    final profile = jsonDecode(profileResponse.body) as Map<String, dynamic>;

    return LineWebProfile(
      userId: profile['userId'] as String,
      displayName: profile['displayName'] as String? ?? 'LINE User',
      pictureUrl: profile['pictureUrl'] as String?,
      pairingId: pairingId,
    );
  }

  static String _randomToken() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _codeChallenge(String verifier) {
    final hash = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(hash.bytes).replaceAll('=', '');
  }
}
