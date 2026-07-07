import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/services/profile_repository.dart';
import 'package:kidtang_flutter/services/push_notification_service.dart';
import 'package:kidtang_flutter/services/social_auth_service.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'locale_provider.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _profileRepo = ProfileRepository();
  final _socialAuth = SocialAuthService();

  // Optional references to sibling providers — set after construction.
  LocaleProvider? _localeProvider;
  GroupsStore? _groupsStore;
  BillsStore? _billsStore;

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
  /// browser tab instead of the installed home-screen PWA.
  bool get lineWebLoginNeedsReturnToApp => _lineWebLoginNeedsReturnToApp;

  /// Reads and clears any error left over from a LINE web login redirect.
  String? consumeLineWebCallbackError() {
    final error = _lineWebCallbackError;
    _lineWebCallbackError = null;
    return error;
  }

  /// Reads and clears any error from a web Google sign-in.
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
    required GroupsStore groupsStore,
    required BillsStore billsStore,
  }) {
    _localeProvider = localeProvider;
    _groupsStore = groupsStore;
    _billsStore = billsStore;
    if (_profile != null) _syncSiblings(_profile!);
  }

  void _syncSiblings(Profile profile) {
    _localeProvider?.initFromProfile(profile.locale);
  }

  void _init() {
    // Initialise SocialAuthService (GoogleSignIn, lifecycle observer, GIS stream).
    _socialAuth.init(
      onGoogleWebError: (error) {
        _googleWebCallbackError = error;
        notifyListeners();
      },
    );

    // When the PWA resumes from background, restart handoff polling if needed.
    _socialAuth.setOnResumed(() {
      if (_user == null) {
        _socialAuth.maybeStartHandoffPolling(
          isLoggedIn: _user != null,
          onSessionRestored: () {}, // onAuthStateChange handles the rest
        );
      }
    });

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

    // LINE web login redirects the whole page away and back — pick up the
    // ?code&state it lands with here instead of the normal cached-session path.
    if (kIsWeb && _hasPendingLineCallback()) {
      _completeLineWebLogin();
      return;
    }

    // Cached session path.
    if (_user != null) {
      _loadProfile().then((_) {
        _initialized = true;
        notifyListeners();
      });
    } else {
      if (kIsWeb) {
        _socialAuth.maybeStartHandoffPolling(
          isLoggedIn: false,
          onSessionRestored: () {}, // onAuthStateChange handles the rest
        );
      }
      _initialized = true;
      notifyListeners();
    }
  }

  bool _hasPendingLineCallback() {
    // Delegate to the same static check LineWebAuthService exposes.
    try {
      // ignore: avoid_dynamic_calls
      return (const bool.fromEnvironment('dart.library.html'))
          ? _checkLineCallbackWeb()
          : false;
    } catch (_) {
      return false;
    }
  }

  bool _checkLineCallbackWeb() {
    // Re-use the existing static getter from LineWebAuthService.
    // Import is conditional — only available on web builds.
    // We call it via the same import that was already in the old auth_provider.
    try {
      // LineWebAuthService.hasPendingCallback is a static bool getter.
      // We can't import it here without a conditional import, so we replicate
      // the check inline using Uri.base (available on web via dart:html shim).
      final uri = Uri.base;
      return uri.queryParameters.containsKey('code') &&
          uri.queryParameters.containsKey('state');
    } catch (_) {
      return false;
    }
  }

  Future<void> _completeLineWebLogin() async {
    final result = await _socialAuth.completeLineWebLogin();
    if (result.error != null) {
      _lineWebCallbackError = result.error;
      _initialized = true;
      notifyListeners();
      return;
    }
    if (result.lineWebNeedsReturnToApp) {
      _lineWebLoginNeedsReturnToApp = true;
      _initialized = true;
      notifyListeners();
    } else {
      if (!_initialized) {
        _initialized = true;
        notifyListeners();
      }
    }
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    try {
      final fetched = await _profileRepo.fetchProfile(_user!.id);
      if (fetched != null) {
        _profile = fetched;
      } else {
        _profile = await _profileRepo.ensureProfile(_user!);
      }
      if (_profile != null) _syncSiblings(_profile!);
      _billsStore?.subscribeRealtime();
      notifyListeners();
      PushNotificationService.saveToken();
    } on PostgrestException catch (e) {
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

  // ── Auth methods ──────────────────────────────────────────────────────────

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

  Future<String?> signInWithGoogle() => _socialAuth.signInWithGoogle();

  Future<String?> signInWithLine() => _socialAuth.signInWithLine();

  Future<void> signOut() async {
    await _socialAuth.signOut();
    await PushNotificationService.clearToken();
    await _supabase.auth.signOut();
    _profile = null;
    _groupsStore?.clear();
    _billsStore?.clear();
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
      await _profileRepo.updateProfile(
        userId: _user!.id,
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        promptpay: promptpay,
      );
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

  Future<String?> completeOnboarding({
    required String displayName,
    required String username,
    String? promptpay,
  }) async {
    if (_user == null) return 'ไม่พบผู้ใช้';
    try {
      await _profileRepo.completeOnboarding(
        userId: _user!.id,
        displayName: displayName,
        username: username,
        promptpay: promptpay,
      );
      await _loadProfile();
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return 'ชื่อผู้ใช้นี้ถูกใช้แล้ว';
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    } catch (e) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    if (_user == null) return false;
    return _profileRepo.isUsernameTaken(username, excludeId: _user!.id);
  }

  Future<void> reloadProfile() async {
    await _loadProfile();
  }

  @override
  void dispose() {
    _socialAuth.dispose();
    super.dispose();
  }
}
