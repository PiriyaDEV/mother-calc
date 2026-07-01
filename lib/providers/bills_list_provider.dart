import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class BillsListProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Bill> _bills = [];
  bool _loading = false;
  bool _hasLoaded = false;
  String? _error;

  List<Bill> get bills => _bills;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  List<Bill> get activeBills =>
      _bills.where((b) => b.status == 'draft').toList();
  List<Bill> get pendingPaymentBills =>
      _bills.where((b) => b.status == 'pending_payment').toList();
  List<Bill> get completedBills =>
      _bills.where((b) => b.status == 'completed').toList();

  Future<void> loadBills({bool force = false}) async {
    if (_hasLoaded && !force) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // No owner_id filter — the bills_select RLS policy already scopes
      // this to bills the user owns OR belongs to via group membership,
      // so filtering by owner_id here would just be more restrictive than
      // what's actually allowed and hide the user's group bills.
      final data = await _supabase
          .from('bills')
          .select(
            '*, bill_members(*, profiles(id, username, display_name, avatar_url)), bill_items(*), groups!bills_group_id_fkey(id, name, emoji)',
          )
          .order('updated_at', ascending: false);

      _bills = (data as List).map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
      _hasLoaded = true;
    } catch (e) {
      _error = 'ไม่สามารถโหลดบิลได้';
      debugPrint('BillsListProvider: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void addBill(Bill bill) {
    _bills = [bill, ..._bills];
    notifyListeners();
  }

  void removeBill(String billId) {
    _bills = _bills.where((b) => b.id != billId).toList();
    notifyListeners();
  }

  void updateBill(Bill updated) {
    _bills = _bills.map((b) => b.id == updated.id ? updated : b).toList();
    notifyListeners();
  }

  void clear() {
    _bills = [];
    _hasLoaded = false;
    _error = null;
    notifyListeners();
  }
}
