import 'profile.dart';

class BillMember {
  final String id;
  final String billId;
  final String name;
  final String color;
  final String? promptpay;
  final bool isExternal;
  final String? userId;
  final Profile? profile;

  const BillMember({
    required this.id,
    required this.billId,
    required this.name,
    required this.color,
    this.promptpay,
    this.isExternal = true,
    this.userId,
    this.profile,
  });

  factory BillMember.fromJson(Map<String, dynamic> json) {
    // Supabase join returns profile under 'profiles' (FK hint) or 'profile'
    final profileRaw = json['profiles'] ?? json['profile'];
    return BillMember(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#4366F4',
      promptpay: json['promptpay'] as String?,
      isExternal: json['is_external'] as bool? ?? true,
      userId: json['user_id'] as String?,
      profile: profileRaw != null
          ? Profile.fromJson(profileRaw as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bill_id': billId,
        'name': name,
        'color': color,
        'promptpay': promptpay,
        'is_external': isExternal,
        'user_id': userId,
      };

  BillMember copyWith({
    String? name,
    String? color,
    String? promptpay,
  }) {
    return BillMember(
      id: id,
      billId: billId,
      name: name ?? this.name,
      color: color ?? this.color,
      promptpay: promptpay ?? this.promptpay,
      isExternal: isExternal,
      userId: userId,
      profile: profile,
    );
  }
}
