import 'dart:async';

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
///
/// Realtime subscriptions keep the store in sync when other users make
/// changes (e.g. a friend creates a bill that includes the current user).
class BillsStore extends ChangeNotifier {
  final _repo = BillsRepository();
  final _supabase = Supabase.instance.client;

  Map<String, Bill> _byId = {};
  bool _loading = false;
  bool _hasLoaded = false;
  String? _error;

  // ── Cached computed lists — invalidated whenever _byId changes ──────
  List<Bill>? _cachedAll;
  List<Bill>? _cachedActive;
  List<Bill>? _cachedPendingPayment;
  List<Bill>? _cachedCompleted;
  List<Bill>? _cachedPersonal;

  // Realtime channels
  RealtimeChannel? _billsChannel;
  RealtimeChannel? _membersChannel;
  RealtimeChannel? _itemsChannel;

  // Debounce timers to avoid hammering DB on rapid changes
  Timer? _reloadAllDebounce;
  final Map<String, Timer> _reloadBillDebounce = {};

  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  /// Invalidate all cached lists. Must be called whenever _byId is mutated.
  void _invalidateCache() {
    _cachedAll = null;
    _cachedActive = null;
    _cachedPendingPayment = null;
    _cachedCompleted = null;
    _cachedPersonal = null;
  }

  List<Bill> get all => _cachedAll ??= _byId.values.toList();
  Bill? getById(String id) => _byId[id];
  List<Bill> forGroup(String groupId) =>
      all.where((b) => b.groupId == groupId).toList();
  List<Bill> get personalBills =>
      _cachedPersonal ??= all.where((b) => b.groupId == null).toList();
  List<Bill> get activeBills =>
      _cachedActive ??= all.where((b) => b.status == 'draft').toList();
  List<Bill> get pendingPaymentBills =>
      _cachedPendingPayment ??=
          all.where((b) => b.status == 'pending_payment').toList();
  List<Bill> get completedBills =>
      _cachedCompleted ??= all.where((b) => b.status == 'completed').toList();

  /// Notify listeners and invalidate caches in one call.
  void _notifyAndInvalidate() {
    _invalidateCache();
    notifyListeners();
  }

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
      _notifyAndInvalidate();
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
      _notifyAndInvalidate();
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
      _notifyAndInvalidate();
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
      _notifyAndInvalidate();
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
    _notifyAndInvalidate();
    try {
      await _repo.deleteBill(billId);
    } catch (e) {
      _byId[billId] = prev;
      _notifyAndInvalidate();
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
    _notifyAndInvalidate();
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
      _notifyAndInvalidate();
      debugPrint('BillsStore.updateBillMeta: $e');
      rethrow;
    }
  }

  Future<void> _updateStatus(String billId, String status) async {
    final prev = _byId[billId];
    if (prev == null) return;
    _byId[billId] = prev.copyWith(status: status);
    _notifyAndInvalidate();
    try {
      await _repo.updateBill(billId, {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _byId[billId] = prev;
      _notifyAndInvalidate();
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
    _notifyAndInvalidate();
    try {
      await _repo.updateBill(billId, {'paid_member_ids': newIds});
    } catch (e) {
      _byId[billId] = prev;
      _notifyAndInvalidate();
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
      _notifyAndInvalidate();
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
      _notifyAndInvalidate();
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
      _notifyAndInvalidate();
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
    _notifyAndInvalidate();
    try {
      await _repo.updateMember(memberId, updates);
    } catch (e) {
      _byId[billId] = prev;
      _notifyAndInvalidate();
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
    _notifyAndInvalidate();
    try {
      await _repo.deleteMember(memberId);
    } catch (e) {
      _byId[billId] = prev;
      _notifyAndInvalidate();
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
      _notifyAndInvalidate();
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
    _notifyAndInvalidate();
    try {
      await _repo.updateItem(itemId, updates);
    } catch (e) {
      _byId[billId] = prev;
      _notifyAndInvalidate();
      debugPrint('BillsStore.editItem: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String billId, String itemId) async {
    final prev = _byId[billId];
    if (prev == null) return;
    final newItems = prev.items.where((item) => item.id != itemId).toList();
    _byId[billId] = prev.copyWith(items: newItems);
    _notifyAndInvalidate();
    try {
      await _repo.deleteItem(itemId);
    } catch (e) {
      _byId[billId] = prev;
      _notifyAndInvalidate();
      debugPrint('BillsStore.deleteItem: $e');
      rethrow;
    }
  }

  void clear() {
    _byId = {};
    _hasLoaded = false;
    _error = null;
    _unsubscribeRealtime();
    _notifyAndInvalidate();
  }

  // ── Realtime ──────────────────────────────────────────────

  /// Subscribe to Supabase Realtime so changes made by other users
  /// (e.g. a friend adding the current user to a bill) are reflected
  /// without requiring a manual refresh.
  void subscribeRealtime() {
    _unsubscribeRealtime();

    // bills table — INSERT means a new bill we might be a member of;
    // UPDATE/DELETE means a bill we already have was changed.
    _billsChannel = _supabase
        .channel('bills_store_bills')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bills',
          callback: (_) => _scheduleReloadAll(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bills',
          callback: (payload) {
            final id = payload.newRecord['id'] as String?;
            if (id != null) _scheduleReloadBill(id);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'bills',
          callback: (payload) {
            final id = payload.oldRecord['id'] as String?;
            if (id != null) {
              _byId.remove(id);
              _notifyAndInvalidate();
            }
          },
        )
        .subscribe();

    // bill_members — any change means the parent bill needs re-fetching
    _membersChannel = _supabase
        .channel('bills_store_members')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bill_members',
          callback: (payload) {
            final billId = (payload.newRecord['bill_id'] ??
                payload.oldRecord['bill_id']) as String?;
            if (billId != null) _scheduleReloadBill(billId);
          },
        )
        .subscribe();

    // bill_items — same as members
    _itemsChannel = _supabase
        .channel('bills_store_items')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bill_items',
          callback: (payload) {
            final billId = (payload.newRecord['bill_id'] ??
                payload.oldRecord['bill_id']) as String?;
            if (billId != null) _scheduleReloadBill(billId);
          },
        )
        .subscribe();
  }

  void _unsubscribeRealtime() {
    _billsChannel?.unsubscribe();
    _membersChannel?.unsubscribe();
    _itemsChannel?.unsubscribe();
    _billsChannel = null;
    _membersChannel = null;
    _itemsChannel = null;
    _reloadAllDebounce?.cancel();
    for (final t in _reloadBillDebounce.values) {
      t.cancel();
    }
    _reloadBillDebounce.clear();
  }

  /// Debounced full reload — used when a new bill INSERT arrives (we don't
  /// know the id yet so we can't do a targeted fetch).
  void _scheduleReloadAll() {
    _reloadAllDebounce?.cancel();
    _reloadAllDebounce = Timer(const Duration(milliseconds: 800), () {
      loadAll(force: true);
    });
  }

  /// Debounced single-bill reload — used for UPDATE/DELETE on bills and
  /// any change on bill_members / bill_items.
  void _scheduleReloadBill(String billId) {
    _reloadBillDebounce[billId]?.cancel();
    _reloadBillDebounce[billId] =
        Timer(const Duration(milliseconds: 400), () async {
      _reloadBillDebounce.remove(billId);
      try {
        final bill = await _repo.fetchById(billId);
        _byId[billId] = bill;
        _notifyAndInvalidate();
      } catch (e) {
        // Bill may have been deleted or is no longer accessible — remove it
        if (_byId.containsKey(billId)) {
          _byId.remove(billId);
          _notifyAndInvalidate();
        }
        debugPrint('BillsStore._scheduleReloadBill($billId): $e');
      }
    });
  }
}
