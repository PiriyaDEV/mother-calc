import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class BillProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

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
    notifyListeners();

    try {
      final billData = await _supabase
          .from('bills')
          .select('*, bill_members(*), bill_items(*)')
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
        if (customShares.isNotEmpty) 'custom_shares': customShares,
        'paid_by': paidBy,
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
        if (customShares != null) 'custom_shares': customShares.isEmpty ? null : customShares,
        if (clearCustomShares) 'custom_shares': null,
        'paid_by': clearPaidBy ? null : paidBy,
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
