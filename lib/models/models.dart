import 'dart:convert';

// ── Bill Settings ─────────────────────────────────────────────
class BillSettings {
  final double serviceCharge;
  final double vat;
  final double tip;
  final double discount;
  final String currency;

  const BillSettings({
    this.serviceCharge = 0,
    this.vat = 0,
    this.tip = 0,
    this.discount = 0,
    this.currency = 'THB',
  });

  factory BillSettings.fromJson(Map<String, dynamic> json) {
    return BillSettings(
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      vat: (json['vat'] as num?)?.toDouble() ?? 0,
      tip: (json['tip'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'THB',
    );
  }

  Map<String, dynamic> toJson() => {
        'serviceCharge': serviceCharge,
        'vat': vat,
        'tip': tip,
        'discount': discount,
        'currency': currency,
      };

  BillSettings copyWith({
    double? serviceCharge,
    double? vat,
    double? tip,
    double? discount,
    String? currency,
  }) {
    return BillSettings(
      serviceCharge: serviceCharge ?? this.serviceCharge,
      vat: vat ?? this.vat,
      tip: tip ?? this.tip,
      discount: discount ?? this.discount,
      currency: currency ?? this.currency,
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
    return BillMember(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#4366F4',
      promptpay: json['promptpay'] as String?,
      isExternal: json['is_external'] as bool? ?? true,
      userId: json['user_id'] as String?,
      profile: json['profile'] != null
          ? Profile.fromJson(json['profile'] as Map<String, dynamic>)
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
class BillItem {
  final String id;
  final String billId;
  final String name;
  final double price;
  final Map<String, double> shares; // memberId -> weight
  final String? paidBy;
  final DateTime? createdAt;

  const BillItem({
    required this.id,
    required this.billId,
    required this.name,
    required this.price,
    required this.shares,
    this.paidBy,
    this.createdAt,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    Map<String, double> shares = {};
    if (json['shares'] != null) {
      final raw = json['shares'];
      if (raw is Map) {
        raw.forEach((k, v) {
          shares[k.toString()] = (v as num).toDouble();
        });
      } else if (raw is String) {
        final decoded = jsonDecode(raw) as Map;
        decoded.forEach((k, v) {
          shares[k.toString()] = (v as num).toDouble();
        });
      }
    }
    return BillItem(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      shares: shares,
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
        'shares': shares,
        'paid_by': paidBy,
        'created_at': createdAt?.toIso8601String(),
      };

  BillItem copyWith({
    String? name,
    double? price,
    Map<String, double>? shares,
    String? paidBy,
  }) {
    return BillItem(
      id: id,
      billId: billId,
      name: name ?? this.name,
      price: price ?? this.price,
      shares: shares ?? this.shares,
      paidBy: paidBy ?? this.paidBy,
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

    return Bill(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String?,
      tags: tags,
      status: json['status'] as String? ?? 'draft',
      ownerId: json['owner_id'] as String,
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
  final String ownerId;
  final DateTime? createdAt;
  final List<GroupMember> members;

  const Group({
    required this.id,
    required this.name,
    this.emoji,
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
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String?,
      ownerId: json['owner_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      members: members,
    );
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final Profile? profile;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    this.profile,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      profile: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Friend ────────────────────────────────────────────────────
class Friend {
  final String id;
  final String userId;
  final String friendId;
  final String status; // 'pending' | 'accepted'
  final Profile? profile;
  final Profile? friendProfile;

  const Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    this.profile,
    this.friendProfile,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      friendId: json['friend_id'] as String,
      status: json['status'] as String? ?? 'pending',
      profile: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      friendProfile: json['friend_profile'] != null
          ? Profile.fromJson(json['friend_profile'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Notification ──────────────────────────────────────────────
class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.title,
    this.body,
    this.data,
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      body: json['body'] as String?,
      data: json['data'] as Map<String, dynamic>?,
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
