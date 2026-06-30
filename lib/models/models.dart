import 'dart:convert';

// ── Bill Settings ─────────────────────────────────────────────
class BillSettings {
  final double serviceCharge;
  final double vat;
  final double tip;
  final double discount;
  final String currency;
  final bool isVat;
  final bool isService;

  const BillSettings({
    this.serviceCharge = 0,
    this.vat = 0,
    this.tip = 0,
    this.discount = 0,
    this.currency = 'THB',
    this.isVat = false,
    this.isService = false,
  });

  factory BillSettings.fromJson(Map<String, dynamic> json) {
    return BillSettings(
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      vat: (json['vat'] as num?)?.toDouble() ?? 0,
      tip: (json['tip'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'THB',
      isVat: json['isVat'] as bool? ?? false,
      isService: json['isService'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'serviceCharge': serviceCharge,
        'vat': vat,
        'tip': tip,
        'discount': discount,
        'currency': currency,
        'isVat': isVat,
        'isService': isService,
      };

  BillSettings copyWith({
    double? serviceCharge,
    double? vat,
    double? tip,
    double? discount,
    String? currency,
    bool? isVat,
    bool? isService,
  }) {
    return BillSettings(
      serviceCharge: serviceCharge ?? this.serviceCharge,
      vat: vat ?? this.vat,
      tip: tip ?? this.tip,
      discount: discount ?? this.discount,
      currency: currency ?? this.currency,
      isVat: isVat ?? this.isVat,
      isService: isService ?? this.isService,
    );
  }
}

// ── Profile ───────────────────────────────────────────────────
class Profile {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? promptpay;
  final DateTime? createdAt;

  const Profile({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.promptpay,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      promptpay: json['promptpay'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'promptpay': promptpay,
        'created_at': createdAt?.toIso8601String(),
      };

  Profile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? promptpay,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      promptpay: promptpay ?? this.promptpay,
      createdAt: createdAt,
    );
  }
}

// ── Bill Member ───────────────────────────────────────────────
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

// ── Bill Item ─────────────────────────────────────────────────
// Schema: id, bill_id, name, price, quantity, member_ids (jsonb array),
//         custom_shares (jsonb map memberId→amount), paid_by (member id)
class BillItem {
  final String id;
  final String billId;
  final String name;
  final double price;
  final double quantity;
  final List<String> memberIds; // bill_member ids who share this item (equal split)
  /// Optional: custom per-member amounts for unequal split.
  /// If non-empty, overrides equal split.
  final Map<String, double> customShares;
  /// The member id who paid upfront for this item.
  final String? paidBy;
  final DateTime? createdAt;

  const BillItem({
    required this.id,
    required this.billId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.memberIds = const [],
    this.customShares = const {},
    this.paidBy,
    this.createdAt,
  });

  /// True when this item uses unequal split amounts.
  bool get isUnequalSplit => customShares.isNotEmpty;

  /// Shares map: memberId → fractional share (0..1) for equal split,
  /// or memberId → absolute amount for unequal split.
  Map<String, double> get shares {
    if (customShares.isNotEmpty) return customShares;
    if (memberIds.isEmpty) return {};
    final share = 1.0 / memberIds.length;
    return {for (final id in memberIds) id: share};
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    List<String> memberIds = [];
    final raw = json['member_ids'];
    if (raw is List) {
      memberIds = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          memberIds = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    Map<String, double> customShares = {};
    final rawShares = json['custom_shares'];
    if (rawShares is Map) {
      customShares = rawShares.map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    } else if (rawShares is String) {
      try {
        final decoded = jsonDecode(rawShares);
        if (decoded is Map) {
          customShares = decoded.map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()));
        }
      } catch (_) {}
    }

    return BillItem(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      memberIds: memberIds,
      customShares: customShares,
      paidBy: json['paid_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bill_id': billId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'member_ids': memberIds,
        'custom_shares': customShares.isEmpty ? null : customShares,
        'paid_by': paidBy,
        'created_at': createdAt?.toIso8601String(),
      };

  BillItem copyWith({
    String? name,
    double? price,
    double? quantity,
    List<String>? memberIds,
    Map<String, double>? customShares,
    String? paidBy,
    bool clearPaidBy = false,
    bool clearCustomShares = false,
  }) {
    return BillItem(
      id: id,
      billId: billId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      memberIds: memberIds ?? this.memberIds,
      customShares: clearCustomShares ? {} : (customShares ?? this.customShares),
      paidBy: clearPaidBy ? null : (paidBy ?? this.paidBy),
      createdAt: createdAt,
    );
  }
}

// ── Bill ──────────────────────────────────────────────────────
class Bill {
  final String id;
  final String title;
  final String? emoji;
  final List<String> tags;
  final String status; // 'draft' | 'completed'
  final String ownerId;
  final String? groupId;
  final String? groupName;
  final String? groupEmoji;
  final BillSettings settings;
  final List<String> paidMemberIds;
  final List<BillMember> members;
  final List<BillItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Bill({
    required this.id,
    required this.title,
    this.emoji,
    this.tags = const [],
    this.status = 'draft',
    required this.ownerId,
    this.groupId,
    this.groupName,
    this.groupEmoji,
    this.settings = const BillSettings(),
    this.paidMemberIds = const [],
    this.members = const [],
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status == 'completed';

  factory Bill.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tags = (json['tags'] as List).map((e) => e.toString()).toList();
      }
    }

    List<String> paidMemberIds = [];
    if (json['paid_member_ids'] != null) {
      if (json['paid_member_ids'] is List) {
        paidMemberIds =
            (json['paid_member_ids'] as List).map((e) => e.toString()).toList();
      }
    }

    BillSettings settings = const BillSettings();
    if (json['settings'] != null) {
      if (json['settings'] is Map) {
        settings =
            BillSettings.fromJson(json['settings'] as Map<String, dynamic>);
      } else if (json['settings'] is String) {
        settings = BillSettings.fromJson(
            jsonDecode(json['settings'] as String) as Map<String, dynamic>);
      }
    }

    List<BillMember> members = [];
    if (json['bill_members'] != null) {
      members = (json['bill_members'] as List)
          .map((e) => BillMember.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<BillItem> items = [];
    if (json['bill_items'] != null) {
      items = (json['bill_items'] as List)
          .map((e) => BillItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse joined group info — try multiple FK hint keys
    String? groupName;
    String? groupEmoji;
    final groupRaw = json['groups!bills_group_id_fkey'] ??
        json['groups'] ??
        json['group'];
    if (groupRaw is Map<String, dynamic>) {
      groupName = groupRaw['name'] as String?;
      groupEmoji = groupRaw['emoji'] as String?;
    }

    return Bill(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String?,
      tags: tags,
      status: json['status'] as String? ?? 'draft',
      ownerId: json['owner_id'] as String,
      groupId: json['group_id'] as String?,
      groupName: groupName,
      groupEmoji: groupEmoji,
      settings: settings,
      paidMemberIds: paidMemberIds,
      members: members,
      items: items,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'tags': tags,
        'status': status,
        'owner_id': ownerId,
        'group_id': groupId,
        'settings': settings.toJson(),
        'paid_member_ids': paidMemberIds,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  Bill copyWith({
    String? title,
    String? emoji,
    List<String>? tags,
    String? status,
    BillSettings? settings,
    List<String>? paidMemberIds,
    List<BillMember>? members,
    List<BillItem>? items,
  }) {
    return Bill(
      id: id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      ownerId: ownerId,
      groupId: groupId,
      settings: settings ?? this.settings,
      paidMemberIds: paidMemberIds ?? this.paidMemberIds,
      members: members ?? this.members,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ── Group ─────────────────────────────────────────────────────
class Group {
  final String id;
  final String name;
  final String? emoji;
  final String? description;
  final List<String> tags;
  final String ownerId;
  final DateTime? createdAt;
  final List<GroupMember> members;

  const Group({
    required this.id,
    required this.name,
    this.emoji,
    this.description,
    this.tags = const [],
    required this.ownerId,
    this.createdAt,
    this.members = const [],
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    List<GroupMember> members = [];
    if (json['group_members'] != null) {
      members = (json['group_members'] as List)
          .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    List<String> tags = [];
    if (json['tags'] is List) {
      tags = (json['tags'] as List).map((e) => e.toString()).toList();
    }
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String?,
      description: json['description'] as String?,
      tags: tags,
      ownerId: json['owner_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      members: members,
    );
  }
}

// GroupMember — role: 'owner'|'member', status: 'pending'|'accepted'|'declined'
class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;   // 'owner' | 'member'
  final String status; // 'pending' | 'accepted' | 'declined'
  final String? invitedBy;
  final Profile? profile;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    this.status = 'pending',
    this.invitedBy,
    this.profile,
  });

  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';

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
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'pending',
      invitedBy: json['invited_by'] as String?,
      profile: profile,
    );
  }
}

// ── Friend ────────────────────────────────────────────────────
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

// ── Notification ──────────────────────────────────────────────
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

// ── Bill Calculation ──────────────────────────────────────────
class MemberItemShare {
  final BillItem item;
  final double amount;

  const MemberItemShare({required this.item, required this.amount});
}

class MemberSummary {
  final BillMember member;
  final double total;
  final List<MemberItemShare> items;

  const MemberSummary({
    required this.member,
    required this.total,
    required this.items,
  });
}

class BillCalculation {
  final double subtotal;
  final double serviceAmount;
  final double vatAmount;
  final double tipAmount;
  final double discountAmount;
  final double total;
  final List<MemberSummary> memberSummaries;

  const BillCalculation({
    required this.subtotal,
    required this.serviceAmount,
    required this.vatAmount,
    required this.tipAmount,
    required this.discountAmount,
    required this.total,
    required this.memberSummaries,
  });
}

class DebtTransaction {
  final BillMember from;
  final BillMember to;
  final double amount;

  const DebtTransaction({
    required this.from,
    required this.to,
    required this.amount,
  });
}
