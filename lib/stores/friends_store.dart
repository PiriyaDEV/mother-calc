import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/repositories/friends_repository.dart';

/// Single in-memory source of truth for the current user's friend rows
/// (accepted + pending, both directions), keyed by row id.
class FriendsStore extends ChangeNotifier {
  final _repo = FriendsRepository();
  final _supabase = Supabase.instance.client;

  Map<String, Friend> _byId = {};
  bool _loading = false;
  bool _hasLoaded = false;
  String? _error;

  // ── Cached derived lists (same reference when content unchanged) ──────────
  // Mirrors BillsStore's listEquals-based cache-invalidation pattern.
  // context.select on these getters now provides real dedup — the selector
  // only fires a rebuild when the list reference actually changes.
  List<Friend> _cachedFriends = const [];
  List<Friend> _cachedPendingReceived = const [];
  List<Friend> _cachedPendingSent = const [];

  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  String? get _myId => _supabase.auth.currentUser?.id;

  List<Friend> get friends => _cachedFriends;
  List<Friend> get pendingReceived => _cachedPendingReceived;
  List<Friend> get pendingSent => _cachedPendingSent;

  int get pendingCount => _cachedPendingReceived.length;

  /// Recompute derived lists and keep the same reference when content is
  /// unchanged — so context.select sees no change and skips the rebuild.
  void _invalidateCache() {
    final myId = _myId;

    // Deduplicate by the other user's ID — guards against two rows for the
    // same pair (e.g. both users sent each other a request before accepting).
    final seen = <String>{};
    final newFriends = _byId.values
        .where((f) => f.status == 'accepted')
        .where((f) {
          final otherId =
              f.requesterId == myId ? f.addresseeId : f.requesterId;
          return seen.add(otherId);
        })
        .toList();
    if (!listEquals(_cachedFriends, newFriends)) {
      _cachedFriends = newFriends;
    }

    final newPendingReceived = myId == null
        ? <Friend>[]
        : _byId.values
            .where((f) => f.status == 'pending' && f.addresseeId == myId)
            .toList();
    if (!listEquals(_cachedPendingReceived, newPendingReceived)) {
      _cachedPendingReceived = newPendingReceived;
    }

    final newPendingSent = myId == null
        ? <Friend>[]
        : _byId.values
            .where((f) => f.status == 'pending' && f.requesterId == myId)
            .toList();
    if (!listEquals(_cachedPendingSent, newPendingSent)) {
      _cachedPendingSent = newPendingSent;
    }
  }

  Future<void> loadFriends({bool force = false}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (_hasLoaded && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _repo.fetchAllRaw(user.id);
      _byId = {
        for (final row in rows) (row['id'] as String): Friend.fromJson(row)
      };
      _hasLoaded = true;
      _invalidateCache();
    } catch (e) {
      _error = 'ไม่สามารถโหลดข้อมูลเพื่อนได้';
      debugPrint('FriendsStore.loadFriends: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Profile?> searchByUsername(String username) async {
    try {
      return await _repo.searchByUsername(username);
    } catch (e) {
      debugPrint('FriendsStore.searchByUsername: $e');
      return null;
    }
  }

  /// Send a friend request to [addresseeId]
  Future<String?> sendFriendRequest(String addresseeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'ไม่ได้เข้าสู่ระบบ';
    try {
      await _repo.insertRequest(user.id, addresseeId);
      await loadFriends(force: true);
      return null;
    } catch (e) {
      debugPrint('FriendsStore.sendFriendRequest: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Accept a friend request by the friends row [rowId]
  Future<String?> acceptFriendRequest(String rowId) async {
    final prev = _byId[rowId];
    if (prev == null) return null;
    _byId[rowId] = prev.copyWith(status: 'accepted');
    _invalidateCache();
    notifyListeners();
    try {
      await _repo.updateStatus(rowId, 'accepted');
      // Re-fetch to flush any duplicate rows (e.g. both users sent requests).
      await loadFriends(force: true);
      return null;
    } catch (e) {
      _byId[rowId] = prev;
      _invalidateCache();
      notifyListeners();
      debugPrint('FriendsStore.acceptFriendRequest: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Decline / delete a friend request by the friends row [rowId]
  Future<String?> declineFriendRequest(String rowId) async {
    final prev = _byId[rowId];
    if (prev == null) return null;
    _byId.remove(rowId);
    _invalidateCache();
    notifyListeners();
    try {
      await _repo.deleteRow(rowId);
      return null;
    } catch (e) {
      _byId[rowId] = prev;
      _invalidateCache();
      notifyListeners();
      debugPrint('FriendsStore.declineFriendRequest: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<String?> removeFriend(String rowId) async {
    final prev = _byId[rowId];
    if (prev == null) return null;
    _byId.remove(rowId);
    _invalidateCache();
    notifyListeners();
    try {
      await _repo.deleteRow(rowId);
      return null;
    } catch (e) {
      _byId[rowId] = prev;
      _invalidateCache();
      notifyListeners();
      debugPrint('FriendsStore.removeFriend: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  // ── Realtime ──────────────────────────────────────────────

  RealtimeChannel? _friendsChannel;
  Timer? _realtimeDebounce;

  /// Subscribe to Supabase Realtime so incoming friend requests and
  /// status changes (accept/decline) are reflected without a manual refresh.
  void subscribeRealtime() {
    _unsubscribeRealtime();
    _friendsChannel = _supabase
        .channel('friends_store_friends')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friends',
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
  }

  void _unsubscribeRealtime() {
    _friendsChannel?.unsubscribe();
    _friendsChannel = null;
    _realtimeDebounce?.cancel();
    _realtimeDebounce = null;
  }

  void _scheduleReload() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 400), () {
      loadFriends(force: true);
    });
  }

  void clear() {
    _byId = {};
    _hasLoaded = false;
    _error = null;
    _invalidateCache();
    _unsubscribeRealtime();
    notifyListeners();
  }
}
