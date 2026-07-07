import 'dart:convert';

// Schema: id, user_id, type, data (jsonb), read, created_at
// NOTE: no title/body columns in schema — derive from type+data
class AppNotification {
  final String id;
  final String userId;
  final String type;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.data = const {},
    this.read = false,
    this.createdAt,
  });

  /// Derived title based on type
  String get title {
    switch (type) {
      case 'group_invite':
        return 'คำเชิญเข้ากลุ่ม';
      case 'friend_request':
        return 'คำขอเป็นเพื่อน';
      case 'friend_accepted':
        return 'ยอมรับคำขอเป็นเพื่อน';
      default:
        return 'การแจ้งเตือน';
    }
  }

  /// Derived body based on data payload
  String get body {
    final groupName = data['group_name'] as String?;
    final inviterName = data['inviter_name'] as String?;
    final username = data['username'] as String?;
    switch (type) {
      case 'group_invite':
        if (groupName != null && inviterName != null) {
          return '$inviterName ชวนคุณเข้าร่วมกลุ่ม "$groupName"';
        }
        return 'คุณได้รับคำเชิญเข้าร่วมกลุ่ม';
      case 'friend_request':
        return '${username ?? 'ผู้ใช้'} ส่งคำขอเป็นเพื่อน';
      case 'friend_accepted':
        return '${username ?? 'ผู้ใช้'} ยอมรับคำขอเป็นเพื่อนของคุณ';
      default:
        return '';
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = {};
    final rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else if (rawData is String) {
      try {
        data = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (_) {}
    }

    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      data: data,
      read: json['read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
