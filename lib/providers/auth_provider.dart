import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  User? _user;
  Profile? _profile;
  bool _initialized = false;

  User? get user => _user;
  Profile? get profile => _profile;
  /// True while waiting for the first auth state event from Supabase.
  bool get loading => !_initialized;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Read the cached session synchronously first so we have an immediate value.
    _user = _supabase.auth.currentUser;

    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      _initialized = true;          // Auth state is now known
      if (_user != null) {
        _loadProfile();
      } else {
        _profile = null;
        notifyListeners();
      }
    });

    // If there is already a session (app reopen), mark as initialized right away
    // and kick off profile load without waiting for the stream event.
    if (_user != null) {
      _initialized = true;
      _loadProfile();
    } else {
      // No cached session – wait a short tick to let Supabase restore session
      // from storage, then mark initialized if still no user.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_initialized) {
          _user = _supabase.auth.currentUser;
          _initialized = true;
          if (_user != null) {
            _loadProfile();
          } else {
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
        notifyListeners();
      } else {
        await _ensureProfile();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _ensureProfile({String? username}) async {
    if (_user == null) return;
    try {
      final email = _user!.email ?? '';
      final defaultUsername = email
          .split('@')
          .first
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final displayName = _user!.userMetadata?['full_name'] as String? ??
          _user!.userMetadata?['name'] as String? ??
          username ??
          defaultUsername;
      final avatarUrl = _user!.userMetadata?['avatar_url'] as String?;

      await _supabase.from('profiles').upsert({
        'id': _user!.id,
        'username': username ?? defaultUsername,
        'display_name': displayName,
        'avatar_url': avatarUrl,
      });

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .single();
      _profile = Profile.fromJson(data);
      notifyListeners();
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

  /// Signs in with Google OAuth.
  Future<String?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.kidtang://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Signs in with LINE OAuth (via Custom OIDC Provider).
  Future<String?> signInWithLine() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider('custom:line'), // custom: prefix is required for custom OIDC providers
        redirectTo: 'io.supabase.kidtang://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _profile = null;
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
