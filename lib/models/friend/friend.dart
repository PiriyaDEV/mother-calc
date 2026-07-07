import 'package:kidtang_flutter/models/me/profile.dart';

// Schema: id, requester_id, addressee_id, status
class Friend {
  final String id;
  final String requesterId;
  final String addresseeId;
  final String status; // 'pending' | 'accepted' | 'declined'
  final Profile? requesterProfile;
  final Profile? addresseeProfile;

  const Friend({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    this.requesterProfile,
    this.addresseeProfile,
  });

  /// Returns the "other" user's profile given the current user's id
  Profile? otherProfile(String myId) {
    if (requesterId == myId) return addresseeProfile;
    return requesterProfile;
  }

  Friend copyWith({String? status}) {
    return Friend(
      id: id,
      requesterId: requesterId,
      addresseeId: addresseeId,
      status: status ?? this.status,
      requesterProfile: requesterProfile,
      addresseeProfile: addresseeProfile,
    );
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    Profile? requesterProfile;
    Profile? addresseeProfile;

    // Supabase returns joined profiles under FK hint keys
    final rp = json['requester_profile'] ??
        json['profiles!friends_requester_id_fkey'];
    final ap = json['addressee_profile'] ??
        json['profiles!friends_addressee_id_fkey'];

    if (rp != null) requesterProfile = Profile.fromJson(rp as Map<String, dynamic>);
    if (ap != null) addresseeProfile = Profile.fromJson(ap as Map<String, dynamic>);

    return Friend(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: json['status'] as String? ?? 'pending',
      requesterProfile: requesterProfile,
      addresseeProfile: addresseeProfile,
    );
  }
}
