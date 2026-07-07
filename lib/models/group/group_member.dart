import 'package:kidtang_flutter/models/me/profile.dart';

// GroupMember — role: 'owner'|'member', status: 'pending'|'accepted'|'declined'
class GroupMember {
  final String id;
  final String groupId;
  final String? userId;       // null for external (non-app) members
  final String? displayName;  // set for external members without a profile
  final String role;   // 'owner' | 'member'
  final String status; // 'pending' | 'accepted' | 'declined'
  final String? invitedBy;
  final Profile? profile;

  const GroupMember({
    required this.id,
    required this.groupId,
    this.userId,
    this.displayName,
    required this.role,
    this.status = 'pending',
    this.invitedBy,
    this.profile,
  });

  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';
  bool get isExternal => userId == null;

  // Best display name: profile name > displayName field > fallback
  String get name =>
      profile?.displayName ??
      profile?.username ??
      displayName ??
      'สมาชิก';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    // Supabase returns the joined profile under the FK hint key
    Profile? profile;
    final profileRaw = json['profiles!group_members_user_id_fkey'] ??
        json['profiles'] ??
        json['profile'];
    if (profileRaw != null) {
      profile = Profile.fromJson(profileRaw as Map<String, dynamic>);
    }
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String?,
      displayName: json['display_name'] as String?,
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'pending',
      invitedBy: json['invited_by'] as String?,
      profile: profile,
    );
  }
}
