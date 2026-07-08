import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/repositories/bills_repository.dart';

const List<String> kBillStatuses = ['draft', 'pending_payment', 'completed'];
const int kBillsPageSize = 20;

/// One status tab's paginated view into [BillsStore._byId].
class BillsListView {
  final List<Bill> items;
  final bool hasMore;
  final bool loaded;
  final bool loadingInitial;
  final bool loadingMore;
  final String? error;

  const BillsListView({
    required this.items,
    required this.hasMore,
    required this.loaded,
    required this.loadingInitial,
    required this.loadingMore,
    required this.error,
  });

  static const empty = BillsListView(
    items: [],
    hasMore: true,
    loaded: false,
    loadingInitial: false,
    loadingMore: false,
    error: null,
  );
}

class _BillsPage {
  List<String> ids = [];
  bool hasMore = true;
  bool loaded = false;
  bool loadingInitial = false;
  bool loadingMore = false;
  String? error;
}

/// Single in-memory source of truth for every bill the current user has
/// touched, keyed by id. Replaces the old BillProvider (single-bill copy) +
/// BillsListProvider (list copy) + GroupsProvider._currentGroupBills
/// (per-group copy) — those three used to drift out of sync with each
/// other because each mutation only patched one of them.
///
/// Unlike the old design, this store does NOT assume `_byId` holds every
/// bill the user can see — the global "all my bills" views (draft/pending/
/// completed tabs, home screen stats/recent) are paginated: `_byId` only
/// holds whatever pages/bills have actually been fetched. Per-group bill
/// lists ([forGroup]) and single-bill lookups ([getById]/[ensureLoaded])
/// still behave as full/on-demand fetches, since a group's bill history is
/// naturally bounded (see plan discussion — group screens need every item
/// for their fairness/analytics math anyway).
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
  String? _error;

  // ── Global paginated views ───────────────────────────────────
  final Map<String, _BillsPage> _pagesByStatus = {
    for (final s in kBillStatuses) s: _BillsPage(),
  };
  List<String> _recentIds = [];
  bool _recentLoading = false;
  bool _recentLoaded = false;
  BillAggregateStats? _stats;
  bool _statsLoading = false;
  bool _statsLoaded = false;

  // ── Per-group bill lists (unpaginated — see class doc) ───────
  final Map<String, List<Bill>> _cachedByGroup = {};

  // Realtime channels
  RealtimeChannel? _billsChannel;
  RealtimeChannel? _membersChannel;
  RealtimeChannel? _itemsChannel;

  // Debounce timers to avoid hammering DB on rapid changes
  Timer? _realtimeInsertDebounce;
  final Map<String, Timer> _reloadBillDebounce = {};

  String? get error => _error;

  BillAggregateStats? get stats => _stats;
  bool get statsLoading => _statsLoading;

  Bill? getById(String id) => _byId[id];

  /// Per-group bills — only ever populated via explicit [loadForGroup],
  /// merged into the shared `_byId` map so there's still only one copy of
  /// any given bill's content.
  List<Bill> forGroup(String groupId) => _cachedByGroup[groupId] ??=
      _byId.values.where((b) => b.groupId == groupId).toList();

  List<Bill> get recentBills =>
      _recentIds.map((id) => _byId[id]).whereType<Bill>().toList();
  bool get recentLoading => _recentLoading;

  BillsListView viewFor(String status) {
    final page = _pagesByStatus[status];
    if (page == null) return BillsListView.empty;
    return BillsListView(
      items: page.ids.map((id) => _byId[id]).whereType<Bill>().toList(),
      hasMore: page.hasMore,
      loaded: page.loaded,
      loadingInitial: page.loadingInitial,
      loadingMore: page.loadingMore,
      error: page.error,
    );
  }

  void _invalidateGroupCache(String? groupId) {
    if (groupId != null) _cachedByGroup.remove(groupId);
  }

  // ── Global aggregate stats ───────────────────────────────────

  Future<void> loadStats({bool force = false}) async {
    if (_statsLoaded && !force) return;
    if (_supabase.auth.currentUser == null) return;
    _statsLoading = true;
    notifyListeners();
    try {
      _stats = await _repo.fetchAggregateStats();
      _statsLoaded = true;
    } catch (e) {
      debugPrint('BillsStore.loadStats: $e');
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecent({bool force = false, int limit = 3}) async {
    if (_recentLoaded && !force) return;
    if (_supabase.auth.currentUser == null) return;
    _recentLoading = true;
    notifyListeners();
    try {
      final bills = await _repo.fetchRecent(limit: limit);
      for (final b in bills) {
        _byId[b.id] = b;
      }
      _recentIds = bills.map((b) => b.id).toList();
      _recentLoaded = true;
    } catch (e) {
      debugPrint('BillsStore.loadRecent: $e');
    } finally {
      _recentLoading = false;
      notifyListeners();
    }
  }

  // ── Per-status paginated tabs (bills_screen) ─────────────────

  Future<void> loadInitialPage(String status, {int limit = kBillsPageSize}) async {
    final page = _pagesByStatus[status];
    if (page == null || page.loaded || page.loadingInitial) return;
    if (_supabase.auth.currentUser == null) return;
    page.loadingInitial = true;
    page.error = null;
    notifyListeners();
    try {
      final bills = await _repo.fetchPage(status: status, offset: 0, limit: limit);
      for (final b in bills) {
        _byId[b.id] = b;
      }
      page.ids = bills.map((b) => b.id).toList();
      page.hasMore = bills.length == limit;
      page.loaded = true;
    } catch (e) {
      page.error = 'ไม่สามารถโหลดบิลได้';
      debugPrint('BillsStore.loadInitialPage($status): $e');
    } finally {
      page.loadingInitial = false;
      notifyListeners();
    }
  }

  Future<void> loadMore(String status, {int limit = kBillsPageSize}) async {
    final page = _pagesByStatus[status];
    if (page == null) return;
    if (page.loadingMore || page.loadingInitial || !page.hasMore) return;
    page.loadingMore = true;
    notifyListeners();
    try {
      final bills = await _repo.fetchPage(
        status: status,
        offset: page.ids.length,
        limit: limit,
      );
      for (final b in bills) {
        _byId[b.id] = b;
      }
      page.ids = [...page.ids, ...bills.map((b) => b.id)];
      page.hasMore = bills.length == limit;
    } catch (e) {
      debugPrint('BillsStore.loadMore($status): $e');
    } finally {
      page.loadingMore = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh — re-fetches from offset 0, keeping the same number of
  /// rows already loaded (so refreshing doesn't visually shrink the list).
  Future<void> refreshPage(String status) async {
    final page = _pagesByStatus[status];
    if (page == null) return;
    final limit = page.ids.isEmpty ? kBillsPageSize : page.ids.length;
    try {
      final bills = await _repo.fetchPage(status: status, offset: 0, limit: limit);
      for (final b in bills) {
        _byId[b.id] = b;
      }
      page.ids = bills.map((b) => b.id).toList();
      page.hasMore = bills.length == limit;
      page.loaded = true;
      page.error = null;
    } catch (e) {
      debugPrint('BillsStore.refreshPage($status): $e');
    } finally {
      notifyListeners();
    }
  }

  /// Fetches bills for one group and merges them into the shared map —
  /// does not replace the whole store, so it's safe to call alongside the
  /// global paginated views above.
  Future<void> loadForGroup(String groupId) async {
    try {
      final bills = await _repo.fetchForGroup(groupId);
      for (final b in bills) {
        _byId[b.id] = b;
      }
      _invalidateGroupCache(groupId);
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

  // ── Page/stats bookkeeping helpers for mutations ─────────────

  void _insertIntoPage(String status, String billId) {
    final page = _pagesByStatus[status];
    if (page == null || !page.loaded) return;
    if (!page.ids.contains(billId)) {
      page.ids = [billId, ...page.ids];
    }
  }

  void _removeFromPage(String status, String billId) {
    final page = _pagesByStatus[status];
    if (page == null) return;
    page.ids = page.ids.where((id) => id != billId).toList();
  }

  /// Fire-and-forget refresh of global aggregates after a mutation that
  /// changes counts/totals — deliberately not awaited so it never blocks
  /// the optimistic UI update that already happened.
  void _refreshAggregatesInBackground({bool refreshRecent = false}) {
    loadStats(force: true);
    if (refreshRecent) loadRecent(force: true);
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
      _insertIntoPage(bill.status, bill.id);
      _invalidateGroupCache(bill.groupId);
      notifyListeners();
      _refreshAggregatesInBackground(refreshRecent: true);
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
    _removeFromPage(prev.status, billId);
    _recentIds = _recentIds.where((id) => id != billId).toList();
    _invalidateGroupCache(prev.groupId);
    notifyListeners();
    try {
      await _repo.deleteBill(billId);
      _refreshAggregatesInBackground();
    } catch (e) {
      _byId[billId] = prev;
      _insertIntoPage(prev.status, billId);
      _invalidateGroupCache(prev.groupId);
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
    _invalidateGroupCache(prev.groupId);
    notifyListeners();
    try {
      await _repo.updateBill(billId, {
        if (title != null) 'title': title,
        if (emoji != null) 'emoji': emoji,
        if (tags != null) 'tags': tags,
        if (settings != null) 'settings': settings.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      // Settings changes affect bills.total server-side (see the
      // recalc_bill_total trigger) — refresh so stats stay accurate.
      if (settings != null) _refreshAggregatesInBackground();
    } catch (e) {
      _byId[billId] = prev;
      _invalidateGroupCache(prev.groupId);
      notifyListeners();
      debugPrint('BillsStore.updateBillMeta: $e');
      rethrow;
    }
  }

  Future<void> _updateStatus(String billId, String status) async {
    final prev = _byId[billId];
    if (prev == null) return;
    _byId[billId] = prev.copyWith(status: status);
    _removeFromPage(prev.status, billId);
    _insertIntoPage(status, billId);
    notifyListeners();
    try {
      await _repo.updateBill(billId, {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _refreshAggregatesInBackground(refreshRecent: true);
    } catch (e) {
      _byId[billId] = prev;
      _removeFromPage(status, billId);
      _insertIntoPage(prev.status, billId);
      notifyListeners();
      debugPrint('BillsStore._updateStatus: $e');
      rethrow;
    }
  }

  Future<void> setPendingPayment(String billId) =>
      _updateStatus(billId, 'pending_payment');
  Future<void> completeBill(String billId) => _updateStatus(billId, 'completed');
  Future<void> reopenBill(String billId) => _updateStatus(billId, 'draft');

  /// Move a draft bill into (or out of) a group.
  /// Pass [groupId] = null to detach the bill from its current group.
  /// [groupName] and [groupEmoji] are used for the optimistic in-memory update
  /// so the UI reflects the new group name immediately without a round-trip.
  Future<void> moveBillToGroup(
    String billId, {
    required String? groupId,
    String? groupName,
    String? groupEmoji,
  }) async {
    final prev = _byId[billId];
    if (prev == null) return;
    final oldGroupId = prev.groupId;

    // Optimistic update
    _byId[billId] = prev.copyWith(
      groupId: groupId,
      groupName: groupName,
      groupEmoji: groupEmoji,
    );
    _invalidateGroupCache(oldGroupId);
    _invalidateGroupCache(groupId);
    notifyListeners();

    try {
      await _repo.updateBill(billId, {
        'group_id': groupId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _refreshAggregatesInBackground(refreshRecent: true);
    } catch (e) {
      // Roll back
      _byId[billId] = prev;
      _invalidateGroupCache(oldGroupId);
      _invalidateGroupCache(groupId);
      notifyListeners();
      debugPrint('BillsStore.moveBillToGroup: $e');
      rethrow;
    }
  }

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
      // Attach profile data (avatar_url) in-memory — insertMemberRaw returns
      // only the raw bill_members row without the profiles join.
      Map<String, dynamic>? profileData;
      if (userId != null) {
        profileData = await _repo.fetchProfile(userId);
      }
      final member = BillMember.fromJson({
        ...data,
        if (profileData != null)
          'profile': {
            'id': userId,
            'username': profileData['username'],
            'display_name': profileData['display_name'],
            'avatar_url': profileData['avatar_url'],
          },
      });
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
      // bills.total/item_count update server-side via the
      // recalc_bill_total trigger — refresh the aggregate view of it.
      _refreshAggregatesInBackground();
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
      if (price != null) _refreshAggregatesInBackground();
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
      _refreshAggregatesInBackground();
    } catch (e) {
      _byId[billId] = prev;
      notifyListeners();
      debugPrint('BillsStore.deleteItem: $e');
      rethrow;
    }
  }

  void clear() {
    _byId = {};
    _error = null;
    for (final page in _pagesByStatus.values) {
      page.ids = [];
      page.hasMore = true;
      page.loaded = false;
      page.error = null;
    }
    _recentIds = [];
    _recentLoaded = false;
    _stats = null;
    _statsLoaded = false;
    _cachedByGroup.clear();
    _unsubscribeRealtime();
    notifyListeners();
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
          callback: (_) => _scheduleRealtimeInsertRefresh(),
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
              final prev = _byId[id];
              _byId.remove(id);
              if (prev != null) {
                _removeFromPage(prev.status, id);
                _invalidateGroupCache(prev.groupId);
              }
              _recentIds = _recentIds.where((rid) => rid != id).toList();
              notifyListeners();
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
    _realtimeInsertDebounce?.cancel();
    for (final t in _reloadBillDebounce.values) {
      t.cancel();
    }
    _reloadBillDebounce.clear();
  }

  /// Debounced refresh after a `bills` INSERT arrives from realtime (we
  /// don't know which bill it is up front, so there's no single id to
  /// patch). Rather than reloading the whole history like the old
  /// full-table `loadAll()` did, this only refreshes pages/lists already
  /// loaded on screen, bounded by however many rows they already hold —
  /// bounded and self-healing, not another unbounded fetch.
  void _scheduleRealtimeInsertRefresh() {
    _realtimeInsertDebounce?.cancel();
    _realtimeInsertDebounce = Timer(const Duration(milliseconds: 800), () {
      for (final status in kBillStatuses) {
        if (_pagesByStatus[status]!.loaded) refreshPage(status);
      }
      if (_recentLoaded) loadRecent(force: true);
      loadStats(force: true);
    });
  }

  /// Debounced single-bill reload — used for UPDATE/DELETE on bills and
  /// any change on bill_members / bill_items.
  void _scheduleReloadBill(String billId) {
    _reloadBillDebounce[billId]?.cancel();
    _reloadBillDebounce[billId] =
        Timer(const Duration(milliseconds: 400), () async {
      _reloadBillDebounce.remove(billId);
      final prevStatus = _byId[billId]?.status;
      try {
        final bill = await _repo.fetchById(billId);
        _byId[billId] = bill;
        if (prevStatus != null && prevStatus != bill.status) {
          _removeFromPage(prevStatus, billId);
          _insertIntoPage(bill.status, billId);
        }
        _invalidateGroupCache(bill.groupId);
        notifyListeners();
      } catch (e) {
        // Bill may have been deleted or is no longer accessible — remove it
        if (_byId.containsKey(billId)) {
          final prev = _byId.remove(billId);
          if (prev != null) {
            _removeFromPage(prev.status, billId);
            _invalidateGroupCache(prev.groupId);
          }
          _recentIds = _recentIds.where((id) => id != billId).toList();
          notifyListeners();
        }
        debugPrint('BillsStore._scheduleReloadBill($billId): $e');
      }
    });
  }
}
