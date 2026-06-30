import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class NotificationsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> loadNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _notifications = (data as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'ไม่สามารถโหลดการแจ้งเตือนได้';
      debugPrint('Error loading notifications: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }

    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final user = _supabase.auth.currentUser;
    if (user == null || _channel != null) return;

    _channel = _supabase
        .channel('notifications_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            try {
              final notif =
                  AppNotification.fromJson(payload.newRecord);
              _notifications = [notif, ..._notifications];
              notifyListeners();
            } catch (e) {
              debugPrint('Realtime notification parse error: $e');
            }
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
      _notifications = _notifications.map((n) {
        if (n.id == notificationId) {
          return AppNotification(
            id: n.id,
            userId: n.userId,
            type: n.type,
            data: n.data,
            read: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('notifications')
          .update({'read': true})
          .eq('user_id', user.id)
          .eq('read', false);
      _notifications = _notifications.map((n) {
        return AppNotification(
          id: n.id,
          userId: n.userId,
          type: n.type,
          data: n.data,
          read: true,
          createdAt: n.createdAt,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<String?> acceptGroupInvite(AppNotification notification) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'ไม่ได้เข้าสู่ระบบ';
    try {
      final groupId = notification.data['group_id'] as String?;
      if (groupId == null) return 'ข้อมูลไม่ถูกต้อง';

      // Update group member status to accepted
      await _supabase
          .from('group_members')
          .update({'status': 'accepted'})
          .eq('group_id', groupId)
          .eq('user_id', user.id);

      await markAsRead(notification.id);
      return null;
    } catch (e) {
      debugPrint('Error accepting group invite: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<String?> declineGroupInvite(AppNotification notification) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'ไม่ได้เข้าสู่ระบบ';
    try {
      final groupId = notification.data['group_id'] as String?;
      if (groupId == null) return 'ข้อมูลไม่ถูกต้อง';

      // Remove group member row
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', user.id);

      await markAsRead(notification.id);
      return null;
    } catch (e) {
      debugPrint('Error declining group invite: $e');
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  void clear() {
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
      _channel = null;
    }
    _notifications = [];
    _error = null;
    notifyListeners();
  }
}
