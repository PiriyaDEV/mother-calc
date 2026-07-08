import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/repositories/groups_repository.dart';

/// Single in-memory source of truth for the groups the current user
/// belongs to, keyed by id. Group bill lists are NOT stored here — they
/// live in [BillsStore] (via `forGroup(groupId)`) so there's only ever one
/// copy of bill data in the app.
class GroupsStore extends ChangeNotifier {
  final _repo = GroupsRepository();
  final _supabase = Supabase.instance.client;

  Map<String, Group> _byId = {};
  bool _loading = false;
  bool _hasLoaded = false;
  String? _error;
  final Set<String> _detailLoadingIds = {};

  int? _groupsCount;
  bool _groupsCountLoading = false;

  List<Group> get groups => _byId.values.toList();
  Group? getById(String id) => _byId[id];
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  bool isDetailLoading(String groupId) => _detailLoadingIds.contains(groupId);

  /// Cheap count of the user's accepted groups — used by the home hero
  /// card so it doesn't need the full [loadGroups] fetch (every group's
  /// full member+profile join) just to show a number.
  int? get groupsCount => _groupsCount;
  bool get groupsCountLoading => _groupsCountLoading;

  Future<void> loadGroupsCount({bool force = false}) async {
    if (_groupsCount != null && !force) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    _groupsCountLoading = true;
    notifyListeners();
    try {
      _groupsCount = await _repo.fetchAcceptedGroupsCount(user.id);
    } catch (e) {
      debugPrint('GroupsStore.loadGroupsCount: $e');
    } finally {
      _groupsCountLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroups({bool force = false}) async {
    if (_hasLoaded && !force) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final groups = await _repo.fetchGroupsForCurrentUser(user.id);
      _byId = {for (final g in groups) g.id: g};
      _hasLoaded = true;
    } catch (e) {
      _error = 'ไม่สามารถโหลดข้อมูลกลุ่มได้';
      debugPrint('GroupsStore.loadGroups: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupDetail(String groupId) async {
    _detailLoadingIds.add(groupId);
    _error = null;
    notifyListeners();
    try {
      final group = await _repo.fetchGroupDetail(groupId);
      _byId[groupId] = group;
    } catch (e) {
      _error = 'ไม่สามารถโหลดข้อมูลกลุ่มได้';
      debugPrint('GroupsStore.loadGroupDetail: $e');
    } finally {
      _detailLoadingIds.remove(groupId);
      notifyListeners();
    }
  }

  Future<Group?> createGroup({
    required String name,
    String? emoji,
    List<String> tags = const [],
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      // No profile-row guard here — AuthProvider._ensureProfile() is the
      // single source of truth for that, and always runs before the user
      // could reach this call.
      final group = await _repo.insertGroup(
        name: name,
        emoji: emoji,
        ownerId: user.id,
        tags: tags,
      );
      await _repo.insertOwnerMembership(group.id, user.id);
      await loadGroups(force: true);
      return group;
    } catch (e) {
      debugPrint('GroupsStore.createGroup: $e');
      return null;
    }
  }

  Future<String?> updateGroup({
    required String groupId,
    String? name,
    String? emoji,
    String? description,
    List<String>? tags,
  }) async {
    final prev = _byId[groupId];
    if (prev == null) return null;
    _byId[groupId] = prev.copyWith(
      name: name,
      emoji: emoji,
      description: description,
      tags: tags,
    );
    notifyListeners();
    try {
      await _repo.updateGroup(groupId, {
        if (name != null) 'name': name,
        if (emoji != null) 'emoji': emoji,
        if (description != null) 'description': description,
        if (tags != null) 'tags': tags,
      });
      return null;
    } catch (e) {
      _byId[groupId] = prev;
      notifyListeners();
      debugPrint('GroupsStore.updateGroup: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<String?> deleteGroup(String groupId) async {
    final prev = _byId[groupId];
    if (prev == null) return null;
    _byId.remove(groupId);
    notifyListeners();
    try {
      await _repo.deleteGroup(groupId);
      return null;
    } catch (e) {
      _byId[groupId] = prev;
      notifyListeners();
      debugPrint('GroupsStore.deleteGroup: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<String?> inviteMember(String groupId, String username) async {
    try {
      final profileData = await _repo.findProfileByUsername(username);
      if (profileData == null) return 'ไม่พบผู้ใช้ @$username';
      final userId = profileData['id'] as String;

      final existing = await _repo.findMembership(groupId, userId);
      if (existing != null) return 'ผู้ใช้นี้เป็นสมาชิกอยู่แล้ว';

      await _repo.insertMembership({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
        'status': 'pending',
      });

      try {
        final currentUser = _supabase.auth.currentUser;
        await _repo.insertNotification({
          'user_id': userId,
          'type': 'group_invite',
          'data': {
            'group_id': groupId,
            'inviter_id': currentUser?.id,
          },
          'read': false,
        });
      } catch (_) {}

      await loadGroupDetail(groupId);
      return null;
    } catch (e) {
      debugPrint('GroupsStore.inviteMember: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Add a friend (app user) directly to the group as an accepted member.
  /// No invite/notification flow — the member is added immediately.
  Future<String?> addDirectMember(
      String groupId, String userId, String displayName) async {
    try {
      final existing = await _repo.findMembership(groupId, userId);
      if (existing != null) return 'ผู้ใช้นี้เป็นสมาชิกอยู่แล้ว';

      await _repo.insertMembership({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
        'status': 'accepted',
      });

      await loadGroupDetail(groupId);
      return null;
    } catch (e) {
      debugPrint('GroupsStore.addDirectMember: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Add an external (non-app-user) member to the group by name.
  Future<String?> addExternalMember(String groupId, String name) async {
    if (name.trim().isEmpty) return 'กรุณาใส่ชื่อ';
    try {
      await _repo.insertMembership({
        'group_id': groupId,
        'user_id': null,
        'display_name': name.trim(),
        'role': 'member',
        'status': 'accepted',
      });
      await loadGroupDetail(groupId);
      return null;
    } catch (e) {
      debugPrint('GroupsStore.addExternalMember: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<String?> removeMember(String groupId, String memberId) async {
    final prev = _byId[groupId];
    if (prev == null) return null;
    final newMembers = prev.members.where((m) => m.id != memberId).toList();
    _byId[groupId] = prev.copyWith(members: newMembers);
    notifyListeners();
    try {
      await _repo.deleteMembership(memberId);
      return null;
    } catch (e) {
      _byId[groupId] = prev;
      notifyListeners();
      debugPrint('GroupsStore.removeMember: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  // ── Realtime ──────────────────────────────────────────────

  RealtimeChannel? _groupsChannel;
  RealtimeChannel? _membersChannel;
  Timer? _realtimeGroupsDebounce;
  final Map<String, Timer> _realtimeGroupDebounce = {};

  /// Subscribe to Supabase Realtime so group invites and membership changes
  /// (accept/decline/remove) are reflected without a manual refresh.
  void subscribeRealtime() {
    _unsubscribeRealtime();

    // groups table — INSERT/UPDATE/DELETE on any group the user belongs to
    _groupsChannel = _supabase
        .channel('groups_store_groups')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'groups',
          callback: (_) => _scheduleReloadGroups(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'groups',
          callback: (payload) {
            final id = payload.newRecord['id'] as String?;
            if (id != null) _scheduleReloadGroupDetail(id);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'groups',
          callback: (payload) {
            final id = payload.oldRecord['id'] as String?;
            if (id != null) {
              _byId.remove(id);
              notifyListeners();
            }
          },
        )
        .subscribe();

    // group_members — any membership change (invite sent/accepted/declined)
    _membersChannel = _supabase
        .channel('groups_store_members')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
          callback: (payload) {
            final groupId = (payload.newRecord['group_id'] ??
                payload.oldRecord['group_id']) as String?;
            if (groupId != null) {
              // If we already have this group, reload its detail.
              // If we don't (new invite), reload the full groups list.
              if (_byId.containsKey(groupId)) {
                _scheduleReloadGroupDetail(groupId);
              } else {
                _scheduleReloadGroups();
              }
            }
          },
        )
        .subscribe();
  }

  void _unsubscribeRealtime() {
    _groupsChannel?.unsubscribe();
    _membersChannel?.unsubscribe();
    _groupsChannel = null;
    _membersChannel = null;
    _realtimeGroupsDebounce?.cancel();
    _realtimeGroupsDebounce = null;
    for (final t in _realtimeGroupDebounce.values) {
      t.cancel();
    }
    _realtimeGroupDebounce.clear();
  }

  void _scheduleReloadGroups() {
    _realtimeGroupsDebounce?.cancel();
    _realtimeGroupsDebounce = Timer(const Duration(milliseconds: 400), () {
      loadGroups(force: true);
      loadGroupsCount(force: true);
    });
  }

  void _scheduleReloadGroupDetail(String groupId) {
    _realtimeGroupDebounce[groupId]?.cancel();
    _realtimeGroupDebounce[groupId] =
        Timer(const Duration(milliseconds: 400), () {
      _realtimeGroupDebounce.remove(groupId);
      loadGroupDetail(groupId);
    });
  }

  void clear() {
    _byId = {};
    _hasLoaded = false;
    _error = null;
    _groupsCount = null;
    _unsubscribeRealtime();
    notifyListeners();
  }
}
