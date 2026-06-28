import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class GroupsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Group> _groups = [];
  Group? _currentGroup;
  List<GroupMember> _currentMembers = [];
  List<Bill> _currentGroupBills = [];
  bool _loading = false;
  bool _detailLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  Group? get currentGroup => _currentGroup;
  List<GroupMember> get currentMembers => _currentMembers;
  List<Bill> get currentGroupBills => _currentGroupBills;
  bool get loading => _loading;
  bool get detailLoading => _detailLoading;
  String? get error => _error;

  Future<void> loadGroups() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _supabase
          .from('group_members')
          .select(
            'group:groups(*, group_members(*, profiles!group_members_user_id_fkey(id, username, display_name, avatar_url, promptpay)))',
          )
          .eq('user_id', user.id)
          .eq('status', 'accepted');

      _groups = (data as List).map((e) {
        final groupData = e['group'] as Map<String, dynamic>;
        return Group.fromJson(groupData);
      }).toList();
    } catch (e) {
      _error = 'ไม่สามารถโหลดข้อมูลกลุ่มได้';
      debugPrint('Error loading groups: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Group?> createGroup({
    required String name,
    String? emoji,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await _supabase.from('groups').insert({
        'name': name,
        'emoji': emoji,
        'owner_id': user.id,
      }).select().single();

      final group = Group.fromJson(data as Map<String, dynamic>);

      // Add owner as member (accepted immediately)
      await _supabase.from('group_members').insert({
        'group_id': group.id,
        'user_id': user.id,
        'role': 'owner',
        'status': 'accepted',
      });

      await loadGroups();
      return group;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return null;
    }
  }

  Future<String?> updateGroup({
    required String groupId,
    String? name,
    String? emoji,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (emoji != null) 'emoji': emoji,
      };
      await _supabase.from('groups').update(updates).eq('id', groupId);
      await loadGroups();
      if (_currentGroup?.id == groupId) {
        await loadGroupDetail(groupId);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating group: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<String?> deleteGroup(String groupId) async {
    try {
      await _supabase.from('groups').delete().eq('id', groupId);
      _groups = _groups.where((g) => g.id != groupId).toList();
      if (_currentGroup?.id == groupId) {
        _currentGroup = null;
        _currentMembers = [];
        _currentGroupBills = [];
      }
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error deleting group: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<void> loadGroupDetail(String groupId) async {
    _detailLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load group with members
      final groupData = await _supabase
          .from('groups')
          .select(
            '*, group_members(*, profiles!group_members_user_id_fkey(id, username, display_name, avatar_url, promptpay))',
          )
          .eq('id', groupId)
          .single();

      _currentGroup = Group.fromJson(groupData as Map<String, dynamic>);
      _currentMembers = _currentGroup!.members;

      // Load group bills
      final billsData = await _supabase
          .from('bills')
          .select('*, bill_members(*), bill_items(*)')
          .eq('group_id', groupId)
          .order('updated_at', ascending: false);

      _currentGroupBills = (billsData as List)
          .map((e) => Bill.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'ไม่สามารถโหลดข้อมูลกลุ่มได้';
      debugPrint('Error loading group detail: $e');
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  Future<String?> inviteMember(String groupId, String username) async {
    try {
      // Find user by username
      final profileData = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (profileData == null) return 'ไม่พบผู้ใช้ @$username';

      final userId = profileData['id'] as String;

      // Check if already a member
      final existing = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) return 'ผู้ใช้นี้เป็นสมาชิกอยู่แล้ว';

      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
        'status': 'pending',
      });

      // Create notification for invited user
      try {
        final currentUser = _supabase.auth.currentUser;
        await _supabase.from('notifications').insert({
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
      debugPrint('Error inviting member: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<String?> removeMember(String groupId, String memberId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('id', memberId);
      await loadGroupDetail(groupId);
      return null;
    } catch (e) {
      debugPrint('Error removing member: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<Bill?> createGroupBill({
    required String groupId,
    required String title,
    String? emoji,
    List<String>? tags,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await _supabase.from('bills').insert({
        'title': title,
        'emoji': emoji,
        'tags': tags ?? [],
        'owner_id': user.id,
        'group_id': groupId,
        'status': 'draft',
        'settings': const BillSettings().toJson(),
        'paid_member_ids': [],
      }).select('*, bill_members(*), bill_items(*)').single();

      final bill = Bill.fromJson(data as Map<String, dynamic>);
      _currentGroupBills = [bill, ..._currentGroupBills];
      notifyListeners();
      return bill;
    } catch (e) {
      debugPrint('Error creating group bill: $e');
      return null;
    }
  }

  Future<String?> deleteGroupBill(String billId) async {
    try {
      await _supabase.from('bills').delete().eq('id', billId);
      _currentGroupBills =
          _currentGroupBills.where((b) => b.id != billId).toList();
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error deleting group bill: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  /// Compute simplified debts across all group bills
  List<_DebtEdge> computeGroupSummary() {
    final Map<String, double> balances = {};

    for (final bill in _currentGroupBills) {
      final subtotal = bill.items.fold(0.0, (s, i) => s + i.price);
      if (subtotal == 0) continue;

      for (final item in bill.items) {
        if (item.memberIds.isEmpty) continue;
        final perPerson = item.price / item.memberIds.length;
        for (final memberId in item.memberIds) {
          balances[memberId] = (balances[memberId] ?? 0) - perPerson;
        }
      }
    }

    // Simplify debts
    final creditors = balances.entries
        .where((e) => e.value > 0.01)
        .map((e) => MapEntry(e.key, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final debtors = balances.entries
        .where((e) => e.value < -0.01)
        .map((e) => MapEntry(e.key, -e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<_DebtEdge> edges = [];
    int ci = 0, di = 0;
    final cAmounts = creditors.map((e) => e.value).toList();
    final dAmounts = debtors.map((e) => e.value).toList();

    while (ci < creditors.length && di < debtors.length) {
      final amount = cAmounts[ci] < dAmounts[di]
          ? cAmounts[ci]
          : dAmounts[di];
      edges.add(_DebtEdge(
        fromId: debtors[di].key,
        toId: creditors[ci].key,
        amount: amount,
      ));
      cAmounts[ci] -= amount;
      dAmounts[di] -= amount;
      if (cAmounts[ci] < 0.01) ci++;
      if (dAmounts[di] < 0.01) di++;
    }

    return edges;
  }

  void clear() {
    _groups = [];
    _currentGroup = null;
    _currentMembers = [];
    _currentGroupBills = [];
    _error = null;
    notifyListeners();
  }
}

class _DebtEdge {
  final String fromId;
  final String toId;
  final double amount;
  const _DebtEdge(
      {required this.fromId, required this.toId, required this.amount});
}
