import 'dart:convert';
import 'bill_settings.dart';
import 'bill_member.dart';
import 'bill_item.dart';

class Bill {
  final String id;
  final String title;
  final String? emoji;
  final List<String> tags;
  final String status; // 'draft' | 'pending_payment' | 'completed'
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
  bool get isPendingPayment => status == 'pending_payment';
  bool get isDraft => status == 'draft';

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
