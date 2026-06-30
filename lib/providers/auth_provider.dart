import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'bills_list_provider.dart';
import 'groups_provider.dart';
import 'locale_provider.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Optional references to sibling providers — set after construction.
  LocaleProvider? _localeProvider;
  GroupsProvider? _groupsProvider;
  BillsListProvider? _billsListProvider;

  User? _user;
  Profile? _profile;
  bool _initialized = false;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get loading => !_initialized;
  bool get isLoggedIn => _user != null;
  bool get needsOnboarding =>
      _user != null &&
      _initialized &&
      _profile != null &&
      !_profile!.onboardingCompleted;

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

      final preferredUsername = username ??
          usernameFromEmail ??
          'user_${_user!.id.substring(0, 8)}';

      final avatarUrl = _user!.userMetadata?['avatar_url'] as String?
          ?? _user!.userMetadata?['picture'] as String?;

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

  /// Signs in with Google using the native SDK (same pattern as LINE).
  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // user cancelled

      final googleId    = googleUser.id;
      final displayName = googleUser.displayName ?? 'Google User';
      final avatarUrl   = googleUser.photoUrl;

      final fakeEmail    = 'google_$googleId@kidtang.app';
      final fakePassword = 'GOOGLE_${googleId}_KIDTANG';

      AuthResponse? authResponse;
      try {
        authResponse = await _supabase.auth.signInWithPassword(
          email: fakeEmail,
          password: fakePassword,
        );
      } on AuthException catch (e) {
        if (e.statusCode == '400' || e.message.toLowerCase().contains('invalid')) {
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
    } on PlatformException catch (e) {
      debugPrint('Google SDK error: ${e.code} — ${e.message}');
      if (e.code == 'sign_in_canceled') return null;
      return e.message ?? 'Google login failed';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  // ── LINE Login (official LINE SDK for Flutter) ────────────────
  // Uses flutter_line_sdk which wraps LINE's native iOS/Android SDKs.
  // No deep-link callback, no manual token exchange — the SDK handles it all.

  /// Signs in with LINE using the official LINE SDK for Flutter.
  /// Gets the LINE profile, then creates/updates the Supabase profile row.
  Future<String?> signInWithLine() async {
    try {
      // Login via LINE SDK — opens LINE app or web login
      final result = await LineSDK.instance.login(
        scopes: ['profile', 'openid'],
      );

      final lineUserId   = result.userProfile?.userId ?? '';
      final displayName  = result.userProfile?.displayName ?? 'LINE User';
      final avatarUrl    = result.userProfile?.pictureUrl?.toString();

      // We use a deterministic email + password derived from the LINE userId
      // to create/sign in to a Supabase account. This avoids needing a custom
      // OIDC provider on Supabase entirely.
      final fakeEmail    = 'line_$lineUserId@kidtang.app';
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
    try { await LineSDK.instance.logout(); } catch (_) {}
    try { await GoogleSignIn().signOut(); } catch (_) {}
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
