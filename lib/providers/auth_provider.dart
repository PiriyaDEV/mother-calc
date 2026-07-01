import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/line_web_auth_service.dart';
import '../services/push_notification_service.dart';
import 'bills_list_provider.dart';
import 'groups_provider.dart';
import 'locale_provider.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  // Shared instance — on web, `signIn()` triggers the GIS popup and the
  // result is delivered via `onCurrentUserChanged` (not a return value).
  final _googleSignIn = GoogleSignIn();

  // Optional references to sibling providers — set after construction.
  LocaleProvider? _localeProvider;
  GroupsProvider? _groupsProvider;
  BillsListProvider? _billsListProvider;

  User? _user;
  Profile? _profile;
  bool _initialized = false;
  String? _lineWebCallbackError;
  String? _googleWebCallbackError;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get loading => !_initialized;
  bool get isLoggedIn => _user != null;
  bool get needsOnboarding =>
      _user != null &&
      _initialized &&
      _profile != null &&
      !_profile!.onboardingCompleted;

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

    // Cached session path — wait for profile before marking initialized.
    if (_user != null) {
      _loadProfile().then((_) {
        _initialized = true;
        notifyListeners();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_initialized) {
          _user = _supabase.auth.currentUser;
          if (_user != null) {
            _loadProfile().then((_) {
              _initialized = true;
              notifyListeners();
            });
          } else {
            _initialized = true;
            notifyListeners();
          }
        }
      });
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
  /// listener (web): creates or signs in to a deterministic Supabase account
  /// for this Google user, then upserts their public profile row.
  Future<String?> _handleGoogleAccount(GoogleSignInAccount googleUser) async {
    try {
      final googleId = googleUser.id;
      final displayName = googleUser.displayName ?? 'Google User';
      final avatarUrl = googleUser.photoUrl;

      final fakeEmail = 'google_$googleId@kidtang.app';
      final fakePassword = 'GOOGLE_${googleId}_KIDTANG';

      AuthResponse? authResponse;
      try {
        authResponse = await _supabase.auth.signInWithPassword(
          email: fakeEmail,
          password: fakePassword,
        );
      } on AuthException catch (e) {
        if (e.statusCode == '400' ||
            e.message.toLowerCase().contains('invalid')) {
          authResponse = await _supabase.auth.signUp(
            email: fakeEmail,
            password: fakePassword,
            data: {
              'display_name': displayName,
              'avatar_url': avatarUrl,
              'google_user_id': googleId,
              'provider': 'google',
            },
          );
        } else {
          rethrow;
        }
      }

      if (authResponse.user != null) {
        final uid = authResponse.user!.id;
        final sanitized = displayName
            .trim()
            .replaceAll(RegExp(r'\s+'), '_')
            .replaceAll(RegExp(r'[^\w฀-๿]'), '');
        final usernameBase = sanitized.isNotEmpty
            ? sanitized
            : 'google_${googleId.substring(0, 8)}';

        await _supabase.from('profiles').upsert({
          'id': uid,
          'username': usernameBase,
          'display_name': displayName,
          'avatar_url': avatarUrl,
        }, onConflict: 'id');
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
      if (error != null) _lineWebCallbackError = error;
      // On success, the signIn/signUp call above triggers onAuthStateChange,
      // which finishes initialization — nothing more to do here.
    } catch (e) {
      debugPrint('LINE web callback error: $e');
      debugPrint('LINE web callback error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('LINE web callback exception message: ${e.toString()}');
      }
      _lineWebCallbackError = 'เข้าสู่ระบบด้วย LINE ไม่สำเร็จ: ${e.toString()}';
    }

    // Safety net in case onAuthStateChange never fires (e.g. the error path
    // above, or an unexpected Supabase hiccup) — don't leave the app stuck
    // on the splash screen.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!_initialized) {
      _user = _supabase.auth.currentUser;
      if (_user != null) await _loadProfile();
      _initialized = true;
      notifyListeners();
    }
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
    try {
      authResponse = await _supabase.auth.signInWithPassword(
        email: fakeEmail,
        password: fakePassword,
      );
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
      } else {
        rethrow;
      }
    }

    // Upsert the public profile row with LINE's display name & avatar
    if (authResponse.user != null) {
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

      // Sync new display name into all bill_members rows linked to this user
      if (displayName != null) {
        await _supabase
            .from('bill_members')
            .update({'name': displayName})
            .eq('user_id', _user!.id)
            .eq('is_external', false);
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
