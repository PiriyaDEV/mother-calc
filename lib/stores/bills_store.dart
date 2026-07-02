import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../repositories/bills_repository.dart';

/// Single in-memory source of truth for every bill the current user can
/// see, keyed by id. Replaces the old BillProvider (single-bill copy) +
/// BillsListProvider (list copy) + GroupsProvider._currentGroupBills
/// (per-group copy) — those three used to drift out of sync with each
/// other because each mutation only patched one of them.
///
/// Updates/deletes on a bill already in the map apply optimistically
/// (mutate the map + notifyListeners immediately, persist to Supabase in
/// the background, roll back on failure) so every screen watching this
/// store reflects the change instantly. Creates await the insert first —
/// there's no existing local copy to update ahead of time.
class BillsStore extends ChangeNotifier {
  final _repo = BillsRepository();
  final _supabase = Supabase.instance.client;

  Map<String, Bill> _byId = {};
  bool _loading = false;
  bool _hasLoaded = false;
  String? _error;

  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  List<Bill> get all => _byId.values.toList();
  Bill? getById(String id) => _byId[id];
  List<Bill> forGroup(String groupId) =>
      all.where((b) => b.groupId == groupId).toList();
  List<Bill> get personalBills => all.where((b) => b.groupId == null).toList();
  List<Bill> get activeBills => all.where((b) => b.status == 'draft').toList();
  List<Bill> get pendingPaymentBills =>
      all.where((b) => b.status == 'pending_payment').toList();
  List<Bill> get completedBills =>
      all.where((b) => b.status == 'completed').toList();

  Future<void> loadAll({bool force = false}) async {
    if (_hasLoaded && !force) return;
    if (_supabase.auth.currentUser == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final bills = await _repo.fetchAllForCurrentUser();
      _byId = {for (final b in bills) b.id: b};
      _hasLoaded = true;
    } catch (e) {
      _error = 'ไม่สามารถโหลดบิลได้';
      debugPrint('BillsStore.loadAll: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetches bills for one group and merges them into the shared map —
  /// does not replace the whole store, so it's safe to call alongside
  /// [loadAll].
  Future<void> loadForGroup(String groupId) async {
    try {
      final bills = await _repo.fetchForGroup(groupId);
      for (final b in bills) {
        _byId[b.id] = b;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('BillsStore.loadForGroup: $e');
    }
  }

  /// Fetches a single bill on demand (e.g. deep link) if it isn't already
  /// cached locally.
  Future<Bill?> ensureLoaded(String billId) async {
    final cached = _byId[billId];
    if (cached != null) return cached;
    try {
      final bill = await _repo.fetchById(billId);
      _byId[billId] = bill;
      notifyListeners();
      return bill;
    } catch (e) {
      debugPrint('BillsStore.ensureLoaded: $e');
      return null;
    }
  }

  Future<Bill?> createBill({
    required String title,
    String? emoji,
    List<String> tags = const [],
    String? groupId,
    BillSettings settings = const BillSettings(),
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final bill = await _repo.insertBill(
        title: title,
        emoji: emoji,
        tags: tags,
        ownerId: user.id,
        groupId: groupId,
        settings: settings,
      );
      _byId[bill.id] = bill;
      notifyListeners();
      return bill;
    } catch (e) {
      debugPrint('BillsStore.createBill: $e');
      return null;
    }
  }

  Future<void> deleteBill(String billId) async {
    final prev = _byId[billId];
    if (prev == null) return;
    _byId.remove(billId);
    notifyListeners();
    try {
      await _repo.deleteBill(billId);
    } catch (e) {
      _byId[billId] = prev;
      notifyListeners();
      debugPrint('BillsStore.deleteBill: $e');
      rethrow;
    }
  }

  Future<void> updateBillMeta(
    String billId, {
    String? title,
    String? emoji,
    List<String>? tags,
    BillSettings? settings,
  }) async {
    final prev = _byId[billId];
    if (prev == null) return;
    _byId[billId] = prev.copyWith(
      title: title ?? prev.title,
      emoji: emoji ?? prev.emoji,
      tags: tags ?? prev.tags,
      settings: settings ?? prev.settings,
    );
    notifyListeners();
    try {
      await _repo.updateBill(billId, {
        if (title != null) 'title': title,
        if (emoji != null) 'emoji': emoji,
        if (tags != null) 'tags': tags,
        if (settings != null) 'settings': settings.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _byId[billId] = prev;
      notifyListeners();
      debugPrint('BillsStore.updateBillMeta: $e');
      rethrow;
    }
  }

  Future<void> _updateStatus(String billId, String status) async {
    final prev = _byId[billId];
    if (prev == null) return;
    _byId[billId] = prev.copyWith(status: status);
    notifyListeners();
    try {
      await _repo.updateBill(billId, {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _byId[billId] = prev;
      notifyListeners();
      debugPrint('BillsStore._updateStatus: $e');
      rethrow;
    }
  }

  Future<void> setPendingPayment(String billId) =>
      _updateStatus(billId, 'pending_payment');
  Future<void> completeBill(String billId) => _updateStatus(billId, 'completed');
  Future<void> reopenBill(String billId) => _updateStatus(billId, 'draft');

  Future<List<String>> toggleMemberPaid(String billId, String memberId) async {
    final prev = _byId[billId];
    if (prev == null) return [];
    final newIds = prev.paidMemberIds.contains(memberId)
        ? prev.paidMemberIds.where((id) => id != memberId).toList()
        : [...prev.paidMemberIds, memberId];
    _byId[billId] = prev.copyWith(paidMemberIds: newIds);
    notifyListeners();
    try {
      await _repo.updateBill(billId, {'paid_member_ids': newIds});
    } catch (e) {
      _byId[billId] = prev;
      notifyListeners();
      debugPrint('BillsStore.toggleMemberPaid: $e');
      rethrow;
    }
    return newIds;
  }

  // ── Members ───────────────────────────────────────────────

  /// Auto-add current logged-in user as first member (is_external=false).
  /// Called after the bill screen loads when the members list is empty.
  Future<void> autoAddCurrentUser(String billId) async {
    final bill = _byId[billId];
    if (bill == null) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (bill.members.any((m) => m.userId == user.id)) return;
    try {
      final profileData = await _repo.fetchProfile(user.id);
      final displayName = profileData?['display_name'] as String? ??
          profileData?['username'] as String? ??
          user.email?.split('@').first ??
          'ฉัน';
      final avatarUrl = profileData?['avatar_url'] as String?;
      final promptpay = profileData?['promptpay'] as String?;
      final data = await _repo.insertMemberRaw({
        'bill_id': billId,
        'user_id': user.id,
        'name': displayName,
        'color': '#4366F4',
        'is_external': false,
        if (promptpay != null) 'promptpay': promptpay,
      });
      // Attach profile data (avatar_url) in-memory since it's not stored
      // in bill_members.
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
      final current = _byId[billId];
      if (current == null) return;
      _byId[billId] = current.copyWith(members: [...current.members, member]);
      notifyListeners();
    } catch (e) {
      debugPrint('BillsStore.autoAddCurrentUser: $e');
    }
  }

  /// Add a group member (linked user or external) to the bill.
  Future<void> addMemberFromGroupMember(
    String billId, {
    required String? userId,
    required String name,
    required String color,
    String? promptpay,
  }) async {
    final bill = _byId[billId];
    if (bill == null) return;
    // Prevent duplicate: by userId for linked users, by name for external
    if (userId != null) {
      if (bill.members.any((m) => m.userId == userId)) return;
    } else {
      if (bill.members.any((m) => m.userId == null && m.name == name)) return;
    }
    try {
      final data = await _repo.insertMemberRaw({
        'bill_id': billId,
        'user_id': userId,
        'name': name,
        'color': color,
        if (promptpay != null) 'promptpay': promptpay,
        'is_external': userId == null,
      });
      final member = BillMember.fromJson(data);
      final current = _byId[billId];
      if (current == null) return;
      _byId[billId] = current.copyWith(members: [...current.members, member]);
      notifyListeners();
    } catch (e) {
      debugPrint('BillsStore.addMemberFromGroupMember: $e');
      rethrow;
    }
  }

  Future<void> addMember(
    String billId, {
    required String name,
    required String color,
    String? promptpay,
  }) async {
    final bill = _byId[billId];
    if (bill == null) return;
    try {
      final data = await _repo.insertMemberRaw({
        'bill_id': billId,
        'name': name,
        'color': color,
        'promptpay': promptpay,
        'is_external': true,
      });
      final member = BillMember.fromJson(data);
      final current = _byId[billId];
      if (current == null) return;
      _byId[billId] = current.copyWith(members: [...current.members, member]);
      notifyListeners();
    } catch (e) {
      debugPrint('BillsStore.addMember: $e');
      rethrow;
    }
  }

  Future<void> editMember(
    String billId,
    String memberId, {
    String? name,
    String? color,
    String? promptpay,
  }) async {
    final prev = _byId[billId];
    if (prev == null) return;
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      'promptpay': promptpay,
    };
    final newMembers = prev.members.map((m) {
      if (m.id == memberId) {
        return m.copyWith(
          name: name ?? m.name,
          color: color ?? m.color,
          promptpay: promptpay,
        );
      }
      return m;
    }).toList();
    _byId[billId] = prev.copyWith(members: newMembers);
    notifyListeners();
    try {
      await _repo.updateMember(memberId, updates);
    } catch (e) {
      _byId[billId] = prev;
      notifyListeners();
      debugPrint('BillsStore.editMember: $e');
      rethrow;
    }
  }

  Future<void> deleteMember(String billId, String memberId) async {
    final prev = _byId[billId];
    if (prev == null) return;
    final newMembers = prev.members.where((m) => m.id != memberId).toList();
    // Remove member from all item memberIds and customShares
    final newItems = prev.items.map((item) {
      final newMemberIds =
          item.memberIds.where((id) => id != memberId).toList();
      final newCustomShares = Map<String, double>.from(item.customShares)
        ..remove(memberId);
      return item.copyWith(
        memberIds: newMemberIds,
        customShares: newCustomShares,
      );
    }).toList();
    _byId[billId] = prev.copyWith(members: newMembers, items: newItems);
    notifyListeners();
    try {
      await _repo.deleteMember(memberId);
    } catch (e) {
      _byId[billId] = prev;
      notifyListeners();
      debugPrint('BillsStore.deleteMember: $e');
      rethrow;
    }
  }

  // ── Items ─────────────────────────────────────────────────

  Future<void> addItem(
    String billId, {
    required String name,
    required double price,
    required List<String> memberIds,
    Map<String, double> customShares = const {},
    String? paidBy,
  }) async {
    final bill = _byId[billId];
    if (bill == null) return;
    try {
      final item = await _repo.insertItem({
        'bill_id': billId,
        'name': name,
        'price': price,
        'member_ids': memberIds,
        if (paidBy != null) 'paid_by': paidBy,
        if (customShares.isNotEmpty) 'custom_shares': customShares,
      });
      final current = _byId[billId];
      if (current == null) return;
      _byId[billId] = current.copyWith(items: [...current.items, item]);
      notifyListeners();
    } catch (e) {
      debugPrint('BillsStore.addItem: $e');
      rethrow;
    }
  }

  Future<void> editItem(
    String billId,
    String itemId, {
    String? name,
    double? price,
    List<String>? memberIds,
    Map<String, double>? customShares,
    String? paidBy,
    bool clearPaidBy = false,
    bool clearCustomShares = false,
  }) async {
    final prev = _byId[billId];
    if (prev == null) return;
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (memberIds != null) 'member_ids': memberIds,
      if (clearPaidBy)
        'paid_by': null
      else if (paidBy != null)
        'paid_by': paidBy,
      if (clearCustomShares)
        'custom_shares': <String, double>{}
      else if (customShares != null)
        'custom_shares': customShares,
    };
    final newItems = prev.items.map((item) {
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
    _byId[billId] = prev.copyWith(items: newItems);
    notifyListeners();
    try {
      await _repo.updateItem(itemId, updates);
    } catch (e) {
      _byId[billId] = prev;
      notifyListeners();
      debugPrint('BillsStore.editItem: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String billId, String itemId) async {
    final prev = _byId[billId];
    if (prev == null) return;
    final newItems = prev.items.where((item) => item.id != itemId).toList();
    _byId[billId] = prev.copyWith(items: newItems);
    notifyListeners();
    try {
      await _repo.deleteItem(itemId);
    } catch (e) {
      _byId[billId] = prev;
      notifyListeners();
      debugPrint('BillsStore.deleteItem: $e');
      rethrow;
    }
  }

  void clear() {
    _byId = {};
    _hasLoaded = false;
    _error = null;
    notifyListeners();
  }
}
