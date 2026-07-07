import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Plain class — no ChangeNotifier, no UI coupling.
/// Owns all raw Supabase profile CRUD so AuthProvider stays focused on
/// session lifecycle and notifyListeners() orchestration.
class ProfileRepository {
  final _supabase = Supabase.instance.client;

  /// Fetch the profile row for [userId]. Returns null if no row exists yet.
  Future<Profile?> fetchProfile(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data != null ? Profile.fromJson(data) : null;
  }

  /// Upsert a minimal profile row for a brand-new user, deriving sensible
  /// defaults from [user] metadata. Falls back to a uid-suffixed username if
  /// the preferred one is already taken (unique-constraint retry).
  Future<Profile?> ensureProfile(User user, {String? username}) async {
    final email = user.email;
    final usernameFromEmail = email != null && email.isNotEmpty
        ? email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        : null;

    final displayName = user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String? ??
        username ??
        usernameFromEmail ??
        'user_${user.id.substring(0, 8)}';

    final preferredUsername =
        username ?? usernameFromEmail ?? 'user_${user.id.substring(0, 8)}';

    final avatarUrl = user.userMetadata?['avatar_url'] as String? ??
        user.userMetadata?['picture'] as String?;

    Future<void> doUpsert(String uname) => _supabase.from('profiles').upsert({
          'id': user.id,
          'username': uname,
          'display_name': displayName,
          'avatar_url': avatarUrl,
        });

    try {
      await doUpsert(preferredUsername);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        await doUpsert('${preferredUsername}_${user.id.substring(0, 6)}');
      } else {
        rethrow; // FK (23503) and others bubble up to caller
      }
    }

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return Profile.fromJson(data);
  }

  /// Upsert profile fields for onboarding completion.
  Future<void> completeOnboarding({
    required String userId,
    required String displayName,
    required String username,
    String? promptpay,
  }) async {
    await _supabase.from('profiles').upsert({
      'id': userId,
      'display_name': displayName,
      'username': username,
      if (promptpay != null && promptpay.isNotEmpty) 'promptpay': promptpay,
      'onboarding_completed': true,
    }, onConflict: 'id');
  }

  /// Upsert arbitrary profile field updates. Also syncs display_name into
  /// bill_members rows (best-effort, alongside the DB trigger).
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? promptpay,
  }) async {
    final updates = <String, dynamic>{
      'id': userId,
      if (displayName != null) 'display_name': displayName,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (promptpay != null) 'promptpay': promptpay,
    };
    await _supabase.from('profiles').upsert(updates);

    // Best-effort sync of the new display name into bill_members — kept
    // as a client-side fallback alongside the profiles_sync_names DB trigger.
    if (displayName != null) {
      try {
        await _supabase
            .from('bill_members')
            .update({'name': displayName})
            .eq('user_id', userId)
            .eq('is_external', false);
      } catch (e) {
        debugPrint('ProfileRepository: failed to sync display name to bill_members: $e');
      }
    }
  }

  /// Returns true if [username] is already taken by a user other than [excludeId].
  Future<bool> isUsernameTaken(String username, {required String excludeId}) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .neq('id', excludeId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }
}
