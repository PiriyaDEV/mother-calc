import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ios_install_prompt.dart';
import 'line_web_auth_service.dart';
import 'line_web_platform.dart';

/// Result returned by every sign-in method.
/// [error] is null on success; non-null on failure.
/// [lineWebNeedsReturnToApp] is true only on iOS after a LINE web login
/// completes in a plain Safari tab — the caller should show the handoff screen.
class SocialAuthResult {
  final String? error;
  final bool lineWebNeedsReturnToApp;
  const SocialAuthResult({this.error, this.lineWebNeedsReturnToApp = false});
}

/// Plain class — no ChangeNotifier, no UI coupling.
/// Owns Google and LINE sign-in mechanics + the LINE web handoff polling loop.
/// AuthProvider delegates to this and calls notifyListeners() on the result.
class SocialAuthService with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn;

  Timer? _handoffPollTimer;

  /// Called by [AuthProvider] during its own [_init].
  /// Sets up GoogleSignIn, registers the lifecycle observer, and wires the
  /// web GIS `onCurrentUserChanged` stream.
  ///
  /// [onGoogleWebError] is called when the GIS popup completes with an error
  /// (web only) — AuthProvider stores the error and calls notifyListeners().
  void init({required void Function(String) onGoogleWebError}) {
    String googleWebClientId;
    try {
      googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.isNotEmpty == true
          ? dotenv.env['GOOGLE_WEB_CLIENT_ID']!
          : const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    } catch (_) {
      googleWebClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    }

    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb && googleWebClientId.isNotEmpty ? googleWebClientId : null,
      serverClientId: !kIsWeb && googleWebClientId.isNotEmpty ? googleWebClientId : null,
      scopes: ['email', 'openid'],
    );

    if (kIsWeb) WidgetsBinding.instance.addObserver(this);

    if (kIsWeb) {
      _googleSignIn.onCurrentUserChanged.listen((account) async {
        if (account == null) return;
        final error = await _handleGoogleAccount(account);
        if (error != null) onGoogleWebError(error);
      });
    }
  }

  void dispose() {
    if (kIsWeb) WidgetsBinding.instance.removeObserver(this);
    _handoffPollTimer?.cancel();
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<String?> signInWithGoogle() async {
    if (kIsWeb) {
      try {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '${Uri.base.origin}/',
          scopes: 'email openid profile',
        );
        return null; // page redirects — never reached
      } catch (e) {
        debugPrint('Google web OAuth error: $e');
        return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
      }
    }
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled
      return await _handleGoogleAccount(googleUser);
    } on PlatformException catch (e) {
      debugPrint('Google SDK error: ${e.code} — ${e.message}');
      if (e.code == 'sign_in_canceled') return null;
      return e.message ?? 'Google login failed';
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<String?> _handleGoogleAccount(GoogleSignInAccount googleUser) async {
    try {
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return 'Google sign-in failed: missing ID token';

      final authResponse = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final user = authResponse.user;
      if (user == null) return 'เกิดข้อผิดพลาด กรุณาลองใหม่';

      final displayName = googleUser.displayName ??
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          user.email?.split('@').first ??
          'Google User';
      final avatarUrl = googleUser.photoUrl ??
          user.userMetadata?['avatar_url'] as String? ??
          user.userMetadata?['picture'] as String?;

      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        final sanitized = displayName
            .trim()
            .replaceAll(RegExp(r'\s+'), '_')
            .replaceAll(RegExp(r'[^\w฀-๿]'), '');
        final usernameBase = sanitized.isNotEmpty
            ? sanitized
            : 'google_${user.id.substring(0, 8)}';
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'username': usernameBase,
          'display_name': displayName,
          'avatar_url': avatarUrl,
        }, onConflict: 'id');
      } else if (avatarUrl != null) {
        await _supabase
            .from('profiles')
            .update({'avatar_url': avatarUrl})
            .eq('id', user.id);
      }

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('Google account handling error: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  // ── LINE ──────────────────────────────────────────────────────────────────

  Future<String?> signInWithLine() async {
    if (kIsWeb) {
      try {
        String channelId;
        try {
          channelId = dotenv.env['LINE_CHANNEL_ID']?.isNotEmpty == true
              ? dotenv.env['LINE_CHANNEL_ID']!
              : const String.fromEnvironment('LINE_CHANNEL_ID');
        } catch (_) {
          channelId = const String.fromEnvironment('LINE_CHANNEL_ID');
        }
        debugPrint('LINE web login: channelId=$channelId');
        if (channelId.isEmpty) return 'LINE_CHANNEL_ID is not configured';
        LineWebAuthService.startLogin(channelId);
      } catch (e, st) {
        debugPrint('LINE web login error: $e\n$st');
        return 'LINE login error: ${e.toString()}';
      }
      return null;
    }
    try {
      final result = await LineSDK.instance.login(scopes: ['profile', 'openid']);
      return await _finishLineSignIn(
        lineUserId: result.userProfile?.userId ?? '',
        displayName: result.userProfile?.displayName ?? 'LINE User',
        avatarUrl: result.userProfile?.pictureUrl?.toString(),
      );
    } on PlatformException catch (e) {
      debugPrint('LINE SDK error: ${e.code} — ${e.message}');
      if (e.code == '3003') return null; // user cancelled
      return e.message ?? 'LINE login failed';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('signInWithLine error: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Called from [AuthProvider._init] when the app loads with LINE's
  /// ?code&state on the URL (redirected back from LINE's login screen).
  ///
  /// Returns a [SocialAuthResult] — AuthProvider stores the error/flag and
  /// calls notifyListeners().
  Future<SocialAuthResult> completeLineWebLogin() async {
    try {
      String channelId;
      try {
        channelId = dotenv.env['LINE_CHANNEL_ID']?.isNotEmpty == true
            ? dotenv.env['LINE_CHANNEL_ID']!
            : const String.fromEnvironment('LINE_CHANNEL_ID');
      } catch (_) {
        channelId = const String.fromEnvironment('LINE_CHANNEL_ID');
      }
      final profile = await LineWebAuthService.completeLogin(channelId);
      final error = await _finishLineSignIn(
        lineUserId: profile.userId,
        displayName: profile.displayName,
        avatarUrl: profile.pictureUrl,
      );
      if (error != null) return SocialAuthResult(error: error);

      // Store the completed session in the DB keyed by loginId so the PWA
      // can pick it up via polling (get_line_login_handoff RPC).
      final loginId = profile.loginId;
      if (loginId.isNotEmpty) {
        final session = _supabase.auth.currentSession;
        if (session != null) {
          try {
            await _supabase.from('line_login_handoffs').insert({
              'pairing_id': loginId,
              'session': session.toJson(),
            });
          } catch (e) {
            debugPrint('Failed to store LINE login handoff: $e');
          }
        }
      }

      return SocialAuthResult(lineWebNeedsReturnToApp: isIos);
    } catch (e) {
      debugPrint('LINE web callback error: $e');
      return SocialAuthResult(
        error: 'เข้าสู่ระบบด้วย LINE ไม่สำเร็จ: ${e.toString()}',
      );
    }
  }

  Future<String?> _finishLineSignIn({
    required String lineUserId,
    required String displayName,
    String? avatarUrl,
  }) async {
    final fakeEmail = 'line_$lineUserId@kidtang.app';
    final fakePassword = 'LINE_${lineUserId}_KIDTANG';

    AuthResponse? authResponse;
    bool isNewUser = false;
    try {
      authResponse = await _supabase.auth.signInWithPassword(
        email: fakeEmail,
        password: fakePassword,
      );
      if (authResponse.user != null) {
        await _supabase
            .from('profiles')
            .update({'avatar_url': avatarUrl})
            .eq('id', authResponse.user!.id);
      }
    } on AuthException catch (e) {
      if (e.statusCode == '400' || e.message.toLowerCase().contains('invalid')) {
        authResponse = await _supabase.auth.signUp(
          email: fakeEmail,
          password: fakePassword,
          data: {
            'display_name': displayName,
            'avatar_url': avatarUrl,
            'line_user_id': lineUserId,
            'provider': 'line',
          },
        );
        isNewUser = true;
      } else {
        rethrow;
      }
    }

    if (isNewUser && authResponse.user != null) {
      final uid = authResponse.user!.id;
      final sanitized = displayName
          .trim()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^\w\u0E00-\u0E7F]'), '');
      final usernameBase = sanitized.isNotEmpty
          ? sanitized
          : 'line_${lineUserId.substring(0, 8)}';
      await _supabase.from('profiles').upsert({
        'id': uid,
        'username': usernameBase,
        'display_name': displayName,
        'avatar_url': avatarUrl,
      }, onConflict: 'id');
    }

    return null;
  }

  // ── LINE web handoff polling ───────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb && state == AppLifecycleState.resumed) {
      _onResumed?.call();
    }
  }

  /// AuthProvider sets this so the lifecycle callback can trigger a re-poll.
  void Function()? _onResumed;
  void setOnResumed(void Function() cb) => _onResumed = cb;

  void maybeStartHandoffPolling({
    required bool isLoggedIn,
    required void Function() onSessionRestored,
  }) {
    if (isLoggedIn || _handoffPollTimer != null) return;
    final loginId = LineWebPlatform.readLoginId();
    if (loginId == null) return;

    var attempts = 0;
    const maxAttempts = 60;
    Future<void> tick() async {
      attempts++;
      if (isLoggedIn) {
        _handoffPollTimer?.cancel();
        _handoffPollTimer = null;
        LineWebPlatform.clearLoginId();
        return;
      }
      if (attempts > maxAttempts) {
        _handoffPollTimer?.cancel();
        _handoffPollTimer = null;
        LineWebPlatform.clearLoginId();
        return;
      }
      try {
        final sessionJson = await _supabase.rpc(
          'get_line_login_handoff',
          params: {'p_pairing_id': loginId},
        );
        if (sessionJson != null) {
          _handoffPollTimer?.cancel();
          _handoffPollTimer = null;
          LineWebPlatform.clearLoginId();
          await _supabase.auth.recoverSession(jsonEncode(sessionJson));
          onSessionRestored();
        }
      } catch (e) {
        debugPrint('LINE login handoff poll failed: $e');
      }
    }

    tick();
    _handoffPollTimer = Timer.periodic(const Duration(seconds: 2), (_) => tick());
  }

  void cancelHandoffPolling() {
    _handoffPollTimer?.cancel();
    _handoffPollTimer = null;
  }

  Future<void> signOut() async {
    try {
      await LineSDK.instance.logout();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
