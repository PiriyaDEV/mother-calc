import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class FriendsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Friend> _friends = [];
  List<Friend> _pendingReceived = [];
  List<Friend> _pendingSent = [];
  bool _loading = false;
  String? _error;

  List<Friend> get friends => _friends;
  List<Friend> get pendingReceived => _pendingReceived;
  List<Friend> get pendingSent => _pendingSent;
  bool get loading => _loading;
  String? get error => _error;
  int get pendingCount => _pendingReceived.length;

  Future<void> loadFriends() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // All friend rows where I am requester or addressee
      final data = await _supabase
          .from('friends')
          .select(
            '*, '
            'requester_profile:profiles!friends_requester_id_fkey(id, username, display_name, avatar_url, promptpay), '
            'addressee_profile:profiles!friends_addressee_id_fkey(id, username, display_name, avatar_url, promptpay)',
          )
          .or('requester_id.eq.${user.id},addressee_id.eq.${user.id}');

      final List<Friend> allFriends = [];
      final List<Friend> pendingReceivedList = [];
      final List<Friend> pendingSentList = [];

      for (final row in (data as List)) {
        final map = Map<String, dynamic>.from(row as Map);

        final rp = map['requester_profile'];
        final ap = map['addressee_profile'];

        final friend = Friend(
          id: map['id'] as String,
          requesterId: map['requester_id'] as String,
          addresseeId: map['addressee_id'] as String,
          status: map['status'] as String? ?? 'pending',
          requesterProfile: rp != null
              ? Profile.fromJson(rp as Map<String, dynamic>)
              : null,
          addresseeProfile: ap != null
              ? Profile.fromJson(ap as Map<String, dynamic>)
              : null,
        );

        if (friend.status == 'accepted') {
          allFriends.add(friend);
        } else if (friend.status == 'pending') {
          if (friend.addresseeId == user.id) {
            pendingReceivedList.add(friend);
          } else {
            pendingSentList.add(friend);
          }
        }
      }

      _friends = allFriends;
      _pendingReceived = pendingReceivedList;
      _pendingSent = pendingSentList;
    } catch (e) {
      _error = 'ไม่สามารถโหลดข้อมูลเพื่อนได้';
      debugPrint('Error loading friends: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Profile?> searchByUsername(String username) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle();
      if (data == null) return null;
      return Profile.fromJson(data);
    } catch (e) {
      debugPrint('Error searching profile: $e');
      return null;
    }
  }

  /// Send a friend request to [addresseeId]
  Future<String?> sendFriendRequest(String addresseeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'ไม่ได้เข้าสู่ระบบ';
    try {
      await _supabase.from('friends').insert({
        'requester_id': user.id,
        'addressee_id': addresseeId,
        'status': 'pending',
      });
      await loadFriends();
      return null;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Accept a friend request by the friends row [rowId]
  Future<String?> acceptFriendRequest(String rowId) async {
    try {
      await _supabase
          .from('friends')
          .update({'status': 'accepted'})
          .eq('id', rowId);
      await loadFriends();
      return null;
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Decline / delete a friend request by the friends row [rowId]
  Future<String?> declineFriendRequest(String rowId) async {
    try {
      await _supabase.from('friends').delete().eq('id', rowId);
      await loadFriends();
      return null;
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<String?> removeFriend(String rowId) async {
    try {
      await _supabase.from('friends').delete().eq('id', rowId);
      await loadFriends();
      return null;
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  void clear() {
    _friends = [];
    _pendingReceived = [];
    _pendingSent = [];
    _error = null;
    notifyListeners();
  }
}
