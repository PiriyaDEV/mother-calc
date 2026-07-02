import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Pure Supabase I/O for the friends table. No state — all caching and
/// optimistic-update logic lives in [FriendsStore].
class FriendsRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAllRaw(String userId) async {
    // All friend rows where I am requester or addressee
    final data = await _supabase
        .from('friends')
        .select(
          '*, '
          'requester_profile:profiles!friends_requester_id_fkey(id, username, display_name, avatar_url, promptpay), '
          'addressee_profile:profiles!friends_addressee_id_fkey(id, username, display_name, avatar_url, promptpay)',
        )
        .or('requester_id.eq.$userId,addressee_id.eq.$userId');
    return (data as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Profile?> searchByUsername(String username) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('username', username)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<void> insertRequest(String requesterId, String addresseeId) async {
    await _supabase.from('friends').insert({
      'requester_id': requesterId,
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  Future<void> updateStatus(String rowId, String status) async {
    await _supabase.from('friends').update({'status': status}).eq('id', rowId);
  }

  Future<void> deleteRow(String rowId) async {
    await _supabase.from('friends').delete().eq('id', rowId);
  }
}
