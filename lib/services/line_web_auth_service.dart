import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'line_web_platform.dart';

class LineWebProfile {
  final String userId;
  final String displayName;
  final String? pictureUrl;

  /// The loginId generated in [LineWebAuthService.startLogin] and echoed
  /// back via `state` — used by AuthProvider to store the completed session
  /// in the DB keyed by this id, so the originating PWA instance can poll
  /// for it (see _maybeStartHandoffPolling in AuthProvider).
  final String loginId;

  LineWebProfile({
    required this.userId,
    required this.displayName,
    this.pictureUrl,
    required this.loginId,
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
    // loginId is saved to this PWA's own localStorage before navigating
    // away.  When LINE's callback lands in a plain Safari tab, the backend
    // stores the completed session keyed by loginId.  The PWA reads its
    // own localStorage on resume/cold-start and polls the backend until
    // the session appears — no cross-context storage sharing needed.
    final loginId = _randomToken();
    LineWebPlatform.saveLoginId(loginId);

    final url = Uri.parse(_authorizeUrl).replace(queryParameters: {
      'response_type': 'code',
      'client_id': channelId,
      'redirect_uri': origin,
      // verifier and loginId are packed into `state` — LINE echoes it back
      // verbatim on redirect so completing login never depends on browser
      // storage surviving the round trip.  `.` is safe as a delimiter since
      // both tokens are base64url (alphabet excludes `.`).
      'state': '$verifier.$loginId',
      'scope': 'profile openid',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });
    LineWebPlatform.redirect(url.toString());
  }

  static bool get hasPendingCallback => LineWebPlatform.hasPendingCallback;

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
    final loginId = stateParts.length > 1 ? stateParts[1] : '';

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
      loginId: loginId,
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
