import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../repositories/friends_repository.dart';

/// Single in-memory source of truth for the current user's friend rows
/// (accepted + pending, both directions), keyed by row id.
class FriendsStore extends ChangeNotifier {
  final _repo = FriendsRepository();
  final _supabase = Supabase.instance.client;

  Map<String, Friend> _byId = {};
  bool _loading = false;
  bool _hasLoaded = false;
  String? _error;

  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  String? get _myId => _supabase.auth.currentUser?.id;

  List<Friend> get friends =>
      _byId.values.where((f) => f.status == 'accepted').toList();
  List<Friend> get pendingReceived {
    final myId = _myId;
    if (myId == null) return [];
    return _byId.values
        .where((f) => f.status == 'pending' && f.addresseeId == myId)
        .toList();
  }

  List<Friend> get pendingSent {
    final myId = _myId;
    if (myId == null) return [];
    return _byId.values
        .where((f) => f.status == 'pending' && f.requesterId == myId)
        .toList();
  }

  int get pendingCount => pendingReceived.length;

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
    notifyListeners();
    try {
      await _repo.updateStatus(rowId, 'accepted');
      return null;
    } catch (e) {
      _byId[rowId] = prev;
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
    notifyListeners();
    try {
      await _repo.deleteRow(rowId);
      return null;
    } catch (e) {
      _byId[rowId] = prev;
      notifyListeners();
      debugPrint('FriendsStore.declineFriendRequest: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<String?> removeFriend(String rowId) async {
    final prev = _byId[rowId];
    if (prev == null) return null;
    _byId.remove(rowId);
    notifyListeners();
    try {
      await _repo.deleteRow(rowId);
      return null;
    } catch (e) {
      _byId[rowId] = prev;
      notifyListeners();
      debugPrint('FriendsStore.removeFriend: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  void clear() {
    _byId = {};
    _hasLoaded = false;
    _error = null;
    notifyListeners();
  }
}
