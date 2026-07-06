import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../repositories/groups_repository.dart';

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

  List<Group> get groups => _byId.values.toList();
  Group? getById(String id) => _byId[id];
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  bool isDetailLoading(String groupId) => _detailLoadingIds.contains(groupId);

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

  void clear() {
    _byId = {};
    _hasLoaded = false;
    _error = null;
    notifyListeners();
  }
}
