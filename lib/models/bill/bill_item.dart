import 'dart:convert';

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

  /// Per-member split *weights* for this item — memberId → fractional
  /// weight (0..1) for equal split, or memberId → absolute amount for
  /// unequal split. These are NOT directly comparable dollar amounts:
  /// always divide by the sum of all weights to get a member's actual
  /// proportional share of [price] (see `simplifyDebts`/bill calculation
  /// in bill_utils.dart) — the ratio is what matters, not the raw value.
  /// Safe to use `.keys`/`.containsKey` directly when you only need "which
  /// members are assigned to this item," regardless of split mode.
  Map<String, double> get splitWeights {
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
