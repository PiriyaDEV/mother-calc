import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Pure Supabase I/O for bills/bill_members/bill_items. No state — all
/// caching and optimistic-update logic lives in [BillsStore].
class BillsRepository {
  final _supabase = Supabase.instance.client;

  static const _billSelectWithGroup =
      '*, bill_members(*, profiles(id, username, display_name, avatar_url)), bill_items(*), groups!bills_group_id_fkey(id, name, emoji)';
  static const _billSelect =
      '*, bill_members(*, profiles(id, username, display_name, avatar_url)), bill_items(*)';

  Future<List<Bill>> fetchAllForCurrentUser() async {
    // No owner_id filter — the bills_select RLS policy already scopes this
    // to bills the user owns OR belongs to via group membership.
    final data = await _supabase
        .from('bills')
        .select(_billSelectWithGroup)
        .order('updated_at', ascending: false);
    return (data as List)
        .map((e) => Bill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Bill>> fetchForGroup(String groupId) async {
    final data = await _supabase
        .from('bills')
        .select(_billSelect)
        .eq('group_id', groupId)
        .order('updated_at', ascending: false);
    return (data as List)
        .map((e) => Bill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Bill> fetchById(String billId) async {
    final data = await _supabase
        .from('bills')
        .select(_billSelect)
        .eq('id', billId)
        .single();
    return Bill.fromJson(data);
  }

  Future<Bill> insertBill({
    required String title,
    String? emoji,
    List<String> tags = const [],
    required String ownerId,
    String? groupId,
    BillSettings settings = const BillSettings(),
  }) async {
    final data = await _supabase.from('bills').insert({
      'title': title,
      'emoji': emoji,
      'tags': tags,
      'owner_id': ownerId,
      'group_id': groupId,
      'status': 'draft',
      'settings': settings.toJson(),
      'paid_member_ids': [],
    }).select('*, bill_members(*), bill_items(*)').single();
    return Bill.fromJson(data);
  }

  Future<void> updateBill(String billId, Map<String, dynamic> updates) async {
    await _supabase.from('bills').update(updates).eq('id', billId);
  }

  Future<void> deleteBill(String billId) async {
    await _supabase.from('bills').delete().eq('id', billId);
  }

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    return await _supabase
        .from('profiles')
        .select('username, display_name, avatar_url, promptpay')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> insertMemberRaw(
      Map<String, dynamic> fields) async {
    return await _supabase.from('bill_members').insert(fields).select().single();
  }

  Future<void> updateMember(
      String memberId, Map<String, dynamic> updates) async {
    await _supabase.from('bill_members').update(updates).eq('id', memberId);
  }

  Future<void> deleteMember(String memberId) async {
    await _supabase.from('bill_members').delete().eq('id', memberId);
  }

  Future<BillItem> insertItem(Map<String, dynamic> fields) async {
    final data =
        await _supabase.from('bill_items').insert(fields).select().single();
    return BillItem.fromJson(data);
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    await _supabase.from('bill_items').update(updates).eq('id', itemId);
  }

  Future<void> deleteItem(String itemId) async {
    await _supabase.from('bill_items').delete().eq('id', itemId);
  }
}
