import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/ios_install_prompt.dart';
import '../services/line_web_auth_service.dart';
import '../services/line_web_platform.dart';
import '../services/push_notification_service.dart';
import 'bills_list_provider.dart';
import 'groups_provider.dart';
import 'locale_provider.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;
  // Shared instance — on web, `signIn()` triggers the GIS popup and the
  // result is delivered via `onCurrentUserChanged` (not a return value).
  // serverClientId (assigned in _init) is required on Android for
  // GoogleSignInAuthentication.idToken to be populated at all — without
  // it, signInWithIdToken has nothing to verify.
  late final GoogleSignIn _googleSignIn;

  // Optional references to sibling providers — set after construction.
  LocaleProvider? _localeProvider;
  GroupsProvider? _groupsProvider;
  BillsListProvider? _billsListProvider;

  User? _user;
  Profile? _profile;
  bool _initialized = false;
  String? _lineWebCallbackError;
  String? _googleWebCallbackError;
  bool _lineWebLoginNeedsReturnToApp = false;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get loading => !_initialized;
  bool get isLoggedIn => _user != null;
  bool get needsOnboarding =>
      _user != null &&
      _initialized &&
      _profile != null &&
      !_profile!.onboardingCompleted;

  /// True once a LINE web login just completed successfully in a plain
  /// browser tab instead of the installed home-screen PWA (see
  /// [_completeLineWebLogin]). The login screen/root widget should show a
  /// "switch back to the app" screen instead of the normal app UI — iOS
  /// gives no way to hand this tab's session back to the PWA instance.
  bool get lineWebLoginNeedsReturnToApp => _lineWebLoginNeedsReturnToApp;

  /// Reads and clears any error left over from a LINE web login redirect
  /// (the redirect tears down the whole app, so there's no Future to
  /// return the error through — the login screen polls this on mount).
  String? consumeLineWebCallbackError() {
    final error = _lineWebCallbackError;
    _lineWebCallbackError = null;
    return error;
  }

  /// Reads and clears any error from a web Google sign-in — like the LINE
  /// web flow above, the rendered GIS button drives sign-in outside of an
  /// awaited call, so `signInWithGoogle()` has no return value to carry it.
  String? consumeGoogleWebCallbackError() {
    final error = _googleWebCallbackError;
    _googleWebCallbackError = null;
    return error;
  }

  AuthProvider() {
    _init();
  }

  /// Wire sibling providers so AuthProvider can push profile data into them.
  void setSiblingProviders({
    required LocaleProvider localeProvider,
    required GroupsProvider groupsProvider,
    required BillsListProvider billsListProvider,
  }) {
    _localeProvider = localeProvider;
    _groupsProvider = groupsProvider;
    _billsListProvider = billsListProvider;
    // If profile already loaded, sync immediately.
    if (_profile != null) {
      _syncSiblings(_profile!);
    }
  }

  void _syncSiblings(Profile profile) {
    _localeProvider?.initFromProfile(profile.locale);
  }

  void _init() {
    // NOTE: String.fromEnvironment MUST be called with a literal string —
    // not a variable — hence the repeated try/catch instead of a helper.
    String googleWebClientId;
    try {
      googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.isNotEmpty == true
          ? dotenv.env['GOOGLE_WEB_CLIENT_ID']!
          : const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    } catch (_) {
      googleWebClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    }
    _googleSignIn = GoogleSignIn(
      serverClientId: googleWebClientId.isNotEmpty ? googleWebClientId : null,
      // Only request scopes that don't require the People API.
      // email + openid are sufficient to get an idToken for Supabase.
      // Omitting 'profile' prevents google_sign_in_web from calling
      // the People API (people.googleapis.com) which is disabled in
      // this project and causes a 403 error.
      scopes: ['email', 'openid'],
    );

    // Lets didChangeAppLifecycleState restart polling when the PWA resumes
    // after the user switched back from Safari.
    if (kIsWeb) WidgetsBinding.instance.addObserver(this);

    _user = _supabase.auth.currentUser;

    _supabase.auth.onAuthStateChange.listen((data) async {
      _user = data.session?.user;
      if (_user != null) {
        await _loadProfile();
      } else {
        _profile = null;
      }
      _initialized = true;
      notifyListeners();
    });

    // Web Google sign-in triggers a GIS popup via _googleSignIn.signIn() —
    // the result lands here on onCurrentUserChanged, not as a return value.
    if (kIsWeb) {
      _googleSignIn.onCurrentUserChanged.listen((account) async {
        if (account == null) return;
        final error = await _handleGoogleAccount(account);
        if (error != null) {
          _googleWebCallbackError = error;
          notifyListeners();
        }
      });
    }

    // LINE web login redirects the whole page away and back — pick up the
    // ?code&state it lands with here instead of the normal cached-session path.
    if (kIsWeb && LineWebAuthService.hasPendingCallback) {
      _completeLineWebLogin();
      return;
    }

    // Cached session path — `Supabase.initialize()` is awaited before
    // runApp(), so any persisted session is already restored by the time
    // we get here; `_user` above reflects it accurately without needing
    // to guess with a delay and re-check.
    if (_user != null) {
      _loadProfile().then((_) {
        _initialized = true;
        notifyListeners();
      });
    } else {
      // Start polling for a handed-off session in the background. This
      // covers both: PWA still open (polling loop runs), and PWA cold-
      // started after being killed (loginId still in localStorage).
      if (kIsWeb) _maybeStartHandoffPolling();
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();
      if (data != null) {
        _profile = Profile.fromJson(data);
      } else {
        await _ensureProfile();
      }
      if (_profile != null) _syncSiblings(_profile!);
      notifyListeners();
      PushNotificationService.saveToken();
    } on PostgrestException catch (e) {
      // Stale cached session — user no longer exists in DB (e.g. after DB reset).
      // Sign out so the user lands on the login screen cleanly.
      if (e.code == '23503' || e.code == '42501') {
        debugPrint('Stale session detected, signing out: $e');
        await _supabase.auth.signOut();
        _user = null;
        _profile = null;
      } else {
        debugPrint('Error loading profile: $e');
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _ensureProfile({String? username}) async {
    if (_user == null) return;
    try {
      final email = _user!.email;
      final usernameFromEmail = email != null && email.isNotEmpty
          ? email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
          : null;

      final displayName = _user!.userMetadata?['full_name'] as String? ??
          _user!.userMetadata?['name'] as String? ??
          username ??
          usernameFromEmail ??
          'user_${_user!.id.substring(0, 8)}';

      final preferredUsername =
          username ?? usernameFromEmail ?? 'user_${_user!.id.substring(0, 8)}';

      final avatarUrl = _user!.userMetadata?['avatar_url'] as String? ??
          _user!.userMetadata?['picture'] as String?;

      // Try preferred username first; if unique constraint fires, fall back to
      // username_<id prefix> which is always unique.
      Future<void> doUpsert(String uname) => _supabase.from('profiles').upsert({
            'id': _user!.id,
            'username': uname,
            'display_name': displayName,
            'avatar_url': avatarUrl,
          });

      try {
        await doUpsert(preferredUsername);
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          await doUpsert('${preferredUsername}_${_user!.id.substring(0, 6)}');
        } else {
          rethrow; // FK (23503) and others bubble up to _loadProfile
        }
      }

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .single();
      _profile = Profile.fromJson(data);
    } on PostgrestException {
      rethrow; // let _loadProfile handle FK / permission errors
    } catch (e) {
      debugPrint('Error ensuring profile: $e');
    }
  }

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Signs up with email/password. Returns null on success (OTP sent),
  /// or an error string on failure.
  Future<String?> signUpWithEmail(
      String email, String password, String username) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'display_name': username},
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Verifies the 6-digit OTP sent to email after sign-up.
  Future<String?> verifyOTP(String email, String token) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Signs in with Google.
  ///
  /// On mobile: calls the native SDK directly and awaits the result.
  /// On web: calls `_googleSignIn.signIn()` to trigger the GIS popup;
  /// the actual sign-in result is picked up by the `onCurrentUserChanged`
  /// listener in [_init] — this method returns null immediately after
  /// the popup is dismissed (success or cancel).
  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled
      // On web the onCurrentUserChanged listener handles the account —
      // calling _handleGoogleAccount here too would double-process it,
      // so skip the explicit handling on web.
      if (kIsWeb) return null;
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

  /// Shared by both the native SDK flow (mobile) and the `onCurrentUserChanged`
  /// listener (web): exchanges Google's ID token for a Supabase session via
  /// `signInWithIdToken`, which Supabase verifies server-side against
  /// Google's public keys. No fake email/password — unlike the old pattern
  /// here (and the LINE flow, which still uses it), the real Google-issued
  /// identity proof means an attacker can't just guess a deterministic
  /// password derived from a googleId to sign in as someone else.
  ///
  /// Requires the Google provider to be enabled in the Supabase dashboard
  /// with this app's Google Client ID(s) added to its authorized list.
  Future<String?> _handleGoogleAccount(GoogleSignInAccount googleUser) async {
    try {
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return 'Google sign-in failed: missing ID token';
      }

      final authResponse = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final user = authResponse.user;
      if (user == null) return 'เกิดข้อผิดพลาด กรุณาลองใหม่';

      // When scopes=['email','openid'], googleUser.displayName/photoUrl may be
      // null because the profile scope was not requested (to avoid the People
      // API 403). Fall back to user_metadata populated by Supabase from the
      // idToken claims (name, picture are standard OIDC claims).
      final displayName = googleUser.displayName
          ?? user.userMetadata?['full_name'] as String?
          ?? user.userMetadata?['name'] as String?
          ?? user.email?.split('@').first
          ?? 'Google User';
      final avatarUrl = googleUser.photoUrl
          ?? user.userMetadata?['avatar_url'] as String?
          ?? user.userMetadata?['picture'] as String?;

      // signInWithIdToken creates the auth user but never touches our
      // public `profiles` table — do that ourselves. A brand new account
      // has no profile row yet; existing users keep whatever
      // username/display_name they set during onboarding and only get
      // avatar_url refreshed in case their Google picture changed.
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
      } else {
        if (avatarUrl != null) {
          await _supabase
              .from('profiles')
              .update({'avatar_url': avatarUrl})
              .eq('id', user.id);
        }
      }

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('Google account handling error: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  // ── LINE Login ──────────────────────────────────────────────────
  // Mobile: flutter_line_sdk wraps LINE's native iOS/Android SDKs — no
  //   deep-link callback, no manual token exchange, the SDK handles it all.
  // Web: flutter_line_sdk has no web implementation, so LineWebAuthService
  //   drives LINE's OAuth2 + PKCE flow directly (see _completeLineWebLogin).

  /// Signs in with LINE. On web this redirects the whole page to LINE's
  /// login screen and never returns normally — [_completeLineWebLogin]
  /// picks up the result after LINE redirects back.
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
        if (channelId.isEmpty) {
          return 'LINE_CHANNEL_ID is not configured';
        }
        LineWebAuthService.startLogin(channelId);
      } catch (e, st) {
        debugPrint('LINE web login error: $e');
        debugPrint('LINE web login stacktrace: $st');
        return 'LINE login error: ${e.toString()}';
      }
      return null;
    }
    try {
      // Login via LINE SDK — opens LINE app or web login
      final result = await LineSDK.instance.login(
        scopes: ['profile', 'openid'],
      );

      return await _finishLineSignIn(
        lineUserId: result.userProfile?.userId ?? '',
        displayName: result.userProfile?.displayName ?? 'LINE User',
        avatarUrl: result.userProfile?.pictureUrl?.toString(),
      );
    } on PlatformException catch (e) {
      debugPrint('LINE SDK error: ${e.code} — ${e.message}');
      if (e.code == '3003') return null; // user cancelled — not an error
      return e.message ?? 'LINE login failed';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('signInWithLine error: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Called from [_init] when the app loads with LINE's ?code&state on the
  /// URL (i.e. we just got redirected back from LINE's login screen).
  ///
  /// This always runs in the context that received the callback — on iOS
  /// that's a plain Safari tab, not the installed home-screen PWA.  After
  /// completing the sign-in, the session is stored in the DB keyed by
  /// loginId so the PWA can poll for it (see [_maybeStartHandoffPolling]).
  Future<void> _completeLineWebLogin() async {
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
      if (error != null) {
        _lineWebCallbackError = error;
        _initialized = true;
        notifyListeners();
        return;
      }

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

      if (!isStandalone) {
        // This tab is plain Safari — show "switch back to the app" UI.
        _lineWebLoginNeedsReturnToApp = true;
        notifyListeners();
      }
      // onAuthStateChange fires from _finishLineSignIn → marks initialized.
    } catch (e) {
      debugPrint('LINE web callback error: $e');
      _lineWebCallbackError = 'เข้าสู่ระบบด้วย LINE ไม่สำเร็จ: ${e.toString()}';
      _initialized = true;
      notifyListeners();
    }
  }

  /// When the PWA comes back to the foreground, restart polling in case
  /// the previous poll loop timed out while the app was suspended.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb && state == AppLifecycleState.resumed && _user == null) {
      _maybeStartHandoffPolling();
    }
  }

  Timer? _handoffPollTimer;

  /// Polls get_line_login_handoff() for a session stashed by
  /// [_completeLineWebLogin].  The PWA saved a loginId in its own
  /// localStorage before redirecting to LINE — that loginId is the key
  /// used to look up the session in the DB.  No cross-context storage
  /// sharing is needed: the PWA reads its own localStorage, Safari writes
  /// to the DB via the backend.
  ///
  /// No-ops if there's no pending loginId (the common case — most logins
  /// complete directly without needing a handoff).
  void _maybeStartHandoffPolling() {
    if (_user != null || _handoffPollTimer != null) return;
    final loginId = LineWebPlatform.readLoginId();
    if (loginId == null) return;

    var attempts = 0;
    const maxAttempts = 60; // ~2 minutes at 2s each.
    Future<void> tick() async {
      attempts++;
      if (_user != null) {
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
          // recoverSession triggers onAuthStateChange → _loadProfile → notifyListeners.
          await _supabase.auth.recoverSession(jsonEncode(sessionJson));
        }
      } catch (e) {
        debugPrint('LINE login handoff poll failed: $e');
      }
    }

    tick(); // Check immediately rather than waiting out the first interval.
    _handoffPollTimer = Timer.periodic(const Duration(seconds: 2), (_) => tick());
  }

  @override
  void dispose() {
    if (kIsWeb) WidgetsBinding.instance.removeObserver(this);
    _handoffPollTimer?.cancel();
    super.dispose();
  }

  /// Shared by both the native LINE SDK flow and the web OAuth flow: creates
  /// or signs in to a deterministic Supabase account for this LINE user, then
  /// upserts their public profile row with LINE's display name & avatar.
  Future<String?> _finishLineSignIn({
    required String lineUserId,
    required String displayName,
    String? avatarUrl,
  }) async {
    // We use a deterministic email + password derived from the LINE userId
    // to create/sign in to a Supabase account. This avoids needing a custom
    // OIDC provider on Supabase entirely.
    final fakeEmail = 'line_$lineUserId@kidtang.app';
    final fakePassword = 'LINE_${lineUserId}_KIDTANG';

    // Try signing in first; if account doesn't exist, sign up.
    AuthResponse? authResponse;
    bool isNewUser = false;
    try {
      authResponse = await _supabase.auth.signInWithPassword(
        email: fakeEmail,
        password: fakePassword,
      );
      // Existing user — do NOT overwrite username/display_name they may have
      // customised. Only update avatar_url in case their LINE pic changed.
      if (authResponse.user != null) {
        await _supabase
            .from('profiles')
            .update({'avatar_url': avatarUrl})
            .eq('id', authResponse.user!.id);
      }
    } on AuthException catch (e) {
      // Account not found → sign up
      if (e.statusCode == '400' ||
          e.message.toLowerCase().contains('invalid')) {
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

    // Only create the profile row for brand-new accounts — existing users
    // keep whatever username/display_name they set during onboarding.
    if (isNewUser && authResponse.user != null) {
      final uid = authResponse.user!.id;

      // Use LINE's display name as the username base (sanitized),
      // e.g. "สมชาย ใจดี" → "สมชาย_ใจดี". Fall back to line_<uid> if empty.
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

  Future<String?> completeOnboarding({
    required String displayName,
    required String username,
    String? promptpay,
  }) async {
    if (_user == null) return 'ไม่พบผู้ใช้';
    try {
      await _supabase.from('profiles').upsert({
        'id': _user!.id,
        'display_name': displayName,
        'username': username,
        if (promptpay != null && promptpay.isNotEmpty) 'promptpay': promptpay,
        'onboarding_completed': true,
      }, onConflict: 'id');
      await _loadProfile();
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return 'ชื่อผู้ใช้นี้ถูกใช้แล้ว';
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    } catch (e) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<void> signOut() async {
    try {
      await LineSDK.instance.logout();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await PushNotificationService.clearToken();
    await _supabase.auth.signOut();
    _profile = null;
    _groupsProvider?.clear();
    _billsListProvider?.clear();
    notifyListeners();
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? promptpay,
  }) async {
    if (_user == null || _profile == null) return;
    try {
      final updates = <String, dynamic>{
        'id': _user!.id,
        if (displayName != null) 'display_name': displayName,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (promptpay != null) 'promptpay': promptpay,
      };
      await _supabase.from('profiles').upsert(updates);

      // Best-effort sync of the new display name into bill_members — kept
      // as a client-side fallback alongside the profiles_sync_names DB
      // trigger (see supabase/migrations). Wrapped separately so a
      // failure here can't block the profile update above from
      // completing/showing in the UI, and isn't silently swallowed either.
      if (displayName != null) {
        try {
          await _supabase
              .from('bill_members')
              .update({'name': displayName})
              .eq('user_id', _user!.id)
              .eq('is_external', false);
        } catch (e) {
          debugPrint('Failed to sync display name to bill_members: $e');
        }
      }

      _profile = _profile!.copyWith(
        displayName: displayName ?? _profile!.displayName,
        username: username ?? _profile!.username,
        avatarUrl: avatarUrl ?? _profile!.avatarUrl,
        promptpay: promptpay ?? _profile!.promptpay,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .neq('id', _user!.id)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> reloadProfile() async {
    await _loadProfile();
  }
}
