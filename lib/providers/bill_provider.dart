import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class BillProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  Bill? _bill;
  List<BillMember> _members = [];
  List<BillItem> _items = [];
  bool _loading = false;
  String? _error;

  Bill? get bill => _bill;
  List<BillMember> get members => _members;
  List<BillItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadBill(String billId) async {
    _loading = true;
    _error = null;
    // Clear stale data so UI doesn't flash old content
    _bill = null;
    _members = [];
    _items = [];
    notifyListeners();

    try {
      final billData = await _supabase
          .from('bills')
          .select('*, bill_members(*, profiles(id, username, display_name, avatar_url)), bill_items(*)')
          .eq('id', billId)
          .single();

      _bill = Bill.fromJson(billData);
      _members = _bill!.members;
      _items = _bill!.items;
    } catch (e) {
      _error = 'ไม่พบบิล';
      debugPrint('Error loading bill: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateBillMeta({
    required String billId,
    String? title,
    String? emoji,
    List<String>? tags,
    BillSettings? settings,
  }) async {
    if (_bill == null) return;
    try {
      final updates = <String, dynamic>{
        if (title != null) 'title': title,
        if (emoji != null) 'emoji': emoji,
        if (tags != null) 'tags': tags,
        if (settings != null) 'settings': settings.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _supabase.from('bills').update(updates).eq('id', billId);
      _bill = _bill!.copyWith(
        title: title ?? _bill!.title,
        emoji: emoji ?? _bill!.emoji,
        tags: tags ?? _bill!.tags,
        settings: settings ?? _bill!.settings,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating bill meta: $e');
      rethrow;
    }
  }

  Future<void> setPendingPayment(String billId) async {
    try {
      await _supabase
          .from('bills')
          .update({'status': 'pending_payment', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', billId);
      _bill = _bill?.copyWith(status: 'pending_payment');
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting pending payment: $e');
      rethrow;
    }
  }

  Future<void> completeBill(String billId) async {
    try {
      await _supabase
          .from('bills')
          .update({'status': 'completed', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', billId);
      _bill = _bill?.copyWith(status: 'completed');
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing bill: $e');
      rethrow;
    }
  }

  Future<void> reopenBill(String billId) async {
    try {
      await _supabase
          .from('bills')
          .update({'status': 'draft', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', billId);
      _bill = _bill?.copyWith(status: 'draft');
      notifyListeners();
    } catch (e) {
      debugPrint('Error reopening bill: $e');
      rethrow;
    }
  }

  Future<void> deleteBill(String billId) async {
    try {
      await _supabase.from('bills').delete().eq('id', billId);
      _bill = null;
      _members = [];
      _items = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting bill: $e');
      rethrow;
    }
  }

  // ── Members ───────────────────────────────────────────────

  /// Auto-add current logged-in user as first member (is_external=false).
  /// Called after loadBill when members list is empty.
  Future<void> autoAddCurrentUser() async {
    if (_bill == null) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    // Check if already added
    if (_members.any((m) => m.userId == user.id)) return;
    try {
      // Fetch profile for display name and avatar
      final profileData = await _supabase
          .from('profiles')
          .select('username, display_name, avatar_url, promptpay')
          .eq('id', user.id)
          .maybeSingle();
      final displayName = profileData?['display_name'] as String? ??
          profileData?['username'] as String? ??
          user.email?.split('@').first ??
          'ฉัน';
      final avatarUrl = profileData?['avatar_url'] as String?;
      final promptpay = profileData?['promptpay'] as String?;
      final data = await _supabase.from('bill_members').insert({
        'bill_id': _bill!.id,
        'user_id': user.id,
        'name': displayName,
        'color': '#4366F4',
        'is_external': false,
        if (promptpay != null) 'promptpay': promptpay,
      }).select().single();
      // Attach profile data (avatar_url) in-memory since it's not stored in bill_members
      final member = BillMember.fromJson({
        ...data,
        'profile': profileData != null
            ? {
                'id': user.id,
                'username': profileData['username'],
                'display_name': profileData['display_name'],
                'avatar_url': avatarUrl,
              }
            : null,
      });
      _members = [..._members, member];
      notifyListeners();
    } catch (e) {
      debugPrint('Error auto-adding current user: $e');
    }
  }

  /// Add a group member (linked user or external) to the bill.
  Future<void> addMemberFromGroupMember({
    required String? userId,
    required String name,
    required String color,
    String? promptpay,
  }) async {
    if (_bill == null) return;
    // Prevent duplicate: by userId for linked users, by name for external
    if (userId != null) {
      if (_members.any((m) => m.userId == userId)) return;
    } else {
      if (_members.any((m) => m.userId == null && m.name == name)) return;
    }
    try {
      final data = await _supabase.from('bill_members').insert({
        'bill_id': _bill!.id,
        'user_id': userId,
        'name': name,
        'color': color,
        if (promptpay != null) 'promptpay': promptpay,
        'is_external': userId == null,
      }).select().single();
      final member = BillMember.fromJson(data);
      _members = [..._members, member];
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding group member: $e');
      rethrow;
    }
  }

  Future<void> addMember({
    required String name,
    required String color,
    String? promptpay,
  }) async {
    if (_bill == null) return;
    try {
      final data = await _supabase.from('bill_members').insert({
        'bill_id': _bill!.id,
        'name': name,
        'color': color,
        'promptpay': promptpay,
        'is_external': true,
      }).select().single();
      final member = BillMember.fromJson(data);
      _members = [..._members, member];
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding member: $e');
      rethrow;
    }
  }

  Future<void> editMember(
    String memberId, {
    String? name,
    String? color,
    String? promptpay,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (color != null) 'color': color,
        'promptpay': promptpay,
      };
      await _supabase.from('bill_members').update(updates).eq('id', memberId);
      _members = _members.map((m) {
        if (m.id == memberId) {
          return m.copyWith(
            name: name ?? m.name,
            color: color ?? m.color,
            promptpay: promptpay,
          );
        }
        return m;
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error editing member: $e');
      rethrow;
    }
  }

  Future<void> deleteMember(String memberId) async {
    try {
      await _supabase.from('bill_members').delete().eq('id', memberId);
      _members = _members.where((m) => m.id != memberId).toList();
      // Remove member from all item memberIds and customShares
      _items = _items.map((item) {
        final newMemberIds = item.memberIds.where((id) => id != memberId).toList();
        final newCustomShares = Map<String, double>.from(item.customShares)
          ..remove(memberId);
        return item.copyWith(
          memberIds: newMemberIds,
          customShares: newCustomShares,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting member: $e');
      rethrow;
    }
  }

  // ── Items ─────────────────────────────────────────────────
  Future<void> addItem({
    required String name,
    required double price,
    required List<String> memberIds,
    Map<String, double> customShares = const {},
    String? paidBy,
  }) async {
    if (_bill == null) return;
    try {
      final data = await _supabase.from('bill_items').insert({
        'bill_id': _bill!.id,
        'name': name,
        'price': price,
        'member_ids': memberIds,
        if (paidBy != null) 'paid_by': paidBy,
        if (customShares.isNotEmpty) 'custom_shares': customShares,
      }).select().single();
      final item = BillItem.fromJson(data);
      _items = [..._items, item];
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding item: $e');
      rethrow;
    }
  }

  Future<void> editItem(
    String itemId, {
    String? name,
    double? price,
    List<String>? memberIds,
    Map<String, double>? customShares,
    String? paidBy,
    bool clearPaidBy = false,
    bool clearCustomShares = false,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (price != null) 'price': price,
        if (memberIds != null) 'member_ids': memberIds,
        if (clearPaidBy) 'paid_by': null
        else if (paidBy != null) 'paid_by': paidBy,
        if (clearCustomShares) 'custom_shares': <String, double>{}
        else if (customShares != null) 'custom_shares': customShares,
      };
      await _supabase.from('bill_items').update(updates).eq('id', itemId);
      _items = _items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            name: name ?? item.name,
            price: price ?? item.price,
            memberIds: memberIds ?? item.memberIds,
            customShares: customShares,
            paidBy: paidBy,
            clearPaidBy: clearPaidBy,
            clearCustomShares: clearCustomShares,
          );
        }
        return item;
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error editing item: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _supabase.from('bill_items').delete().eq('id', itemId);
      _items = _items.where((item) => item.id != itemId).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting item: $e');
      rethrow;
    }
  }

  Future<List<String>> toggleMemberPaid(
    String billId,
    String memberId,
    List<String> currentPaidIds,
  ) async {
    final newIds = currentPaidIds.contains(memberId)
        ? currentPaidIds.where((id) => id != memberId).toList()
        : [...currentPaidIds, memberId];

    await _supabase
        .from('bills')
        .update({'paid_member_ids': newIds})
        .eq('id', billId);

    _bill = _bill?.copyWith(paidMemberIds: newIds);
    notifyListeners();
    return newIds;
  }

  void clear() {
    _bill = null;
    _members = [];
    _items = [];
    _error = null;
    notifyListeners();
  }
}
