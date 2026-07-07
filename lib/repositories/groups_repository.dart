import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';

/// Pure Supabase I/O for groups/group_members. No state — all caching and
/// optimistic-update logic lives in [GroupsStore].
class GroupsRepository {
  final _supabase = Supabase.instance.client;

  static const _memberJoin =
      'group_members(*, profiles!group_members_user_id_fkey(id, username, display_name, avatar_url, promptpay))';

  Future<List<Group>> fetchGroupsForCurrentUser(String userId) async {
    final data = await _supabase
        .from('group_members')
        .select('group:groups(*, $_memberJoin)')
        .eq('user_id', userId)
        .eq('status', 'accepted');

    return (data as List).map((e) {
      final groupData = e['group'] as Map<String, dynamic>;
      return Group.fromJson(groupData);
    }).toList();
  }

  /// Cheap count-only query — backs the home hero card's group count
  /// without loading every group's full member+profile join.
  Future<int> fetchAcceptedGroupsCount(String userId) async {
    final response = await _supabase
        .from('group_members')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'accepted')
        .count(CountOption.exact);
    return response.count;
  }

  Future<Group> fetchGroupDetail(String groupId) async {
    final data = await _supabase
        .from('groups')
        .select('*, $_memberJoin')
        .eq('id', groupId)
        .single();
    return Group.fromJson(data);
  }

  Future<Group> insertGroup({
    required String name,
    String? emoji,
    required String ownerId,
    List<String> tags = const [],
  }) async {
    final data = await _supabase.from('groups').insert({
      'name': name,
      'emoji': emoji,
      'owner_id': ownerId,
      if (tags.isNotEmpty) 'tags': tags,
    }).select().single();
    return Group.fromJson(data);
  }

  Future<void> insertOwnerMembership(String groupId, String userId) async {
    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'owner',
      'status': 'accepted',
    });
  }

  Future<void> updateGroup(String groupId, Map<String, dynamic> updates) async {
    await _supabase.from('groups').update(updates).eq('id', groupId);
  }

  Future<void> deleteGroup(String groupId) async {
    await _supabase.from('groups').delete().eq('id', groupId);
  }

  Future<Map<String, dynamic>?> findProfileByUsername(String username) async {
    return await _supabase
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> findMembership(
      String groupId, String userId) async {
    return await _supabase
        .from('group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<void> insertMembership(Map<String, dynamic> fields) async {
    await _supabase.from('group_members').insert(fields);
  }

  Future<void> insertNotification(Map<String, dynamic> fields) async {
    await _supabase.from('notifications').insert(fields);
  }

  Future<void> deleteMembership(String memberRowId) async {
    await _supabase.from('group_members').delete().eq('id', memberRowId);
  }
}
