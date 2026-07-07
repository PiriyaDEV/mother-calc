import 'group_member.dart';

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

  Group copyWith({
    String? name,
    String? emoji,
    String? description,
    List<String>? tags,
    List<GroupMember>? members,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      ownerId: ownerId,
      createdAt: createdAt,
      members: members ?? this.members,
    );
  }
}
