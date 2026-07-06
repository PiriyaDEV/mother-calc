import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ── Number formatting ─────────────────────────────────────────
// Static cached formatters — NumberFormat is expensive to construct.
final _fmtWhole = NumberFormat('#,##0', 'en_US');
final _fmtDecimal = NumberFormat('#,##0.##', 'en_US');

String formatNumber(double value, {int decimals = 2}) {
  if (value == value.truncateToDouble()) {
    return _fmtWhole.format(value);
  }
  return _fmtDecimal.format(value);
}

String formatCurrency(double value, String currency) {
  return '${formatNumber(value)} $currency';
}

// ── Total emoji ───────────────────────────────────────────────
String getTotalEmoji(double total) {
  if (total < 100) return '🤏';
  if (total < 500) return '💸';
  if (total < 1000) return '💰';
  if (total < 3000) return '🤑';
  return '🏦';
}

// ── Color from hex string ─────────────────────────────────────
// Memoize parsed colors — hex strings repeat constantly across members/items.
final _colorCache = <String, Color>{};

Color colorFromHex(String hex) {
  return _colorCache.putIfAbsent(hex, () {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) {
        return Color(int.parse('FF$h', radix: 16));
      } else if (h.length == 8) {
        return Color(int.parse(h, radix: 16));
      }
    } catch (_) {}
    return AppColors.primary;
  });
}

String hexFromColor(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

// ── Bill calculation ──────────────────────────────────────────
BillCalculation calculateBill(Bill bill) {
  final members = bill.members;
  final items = bill.items;
  final settings = bill.settings;

  // Subtotal = sum of all item prices
  final subtotal = items.fold<double>(0, (sum, item) => sum + item.price);

  // Service charge
  final serviceAmount = subtotal * (settings.serviceCharge / 100);

  // VAT applied on subtotal + service charge
  final vatBase = subtotal + serviceAmount;
  final vatAmount = vatBase * (settings.vat / 100);

  // Tip (flat amount)
  final tipAmount = settings.tip;

  // Discount (flat amount)
  final discountAmount = settings.discount;

  // Total
  final total = subtotal + serviceAmount + vatAmount + tipAmount - discountAmount;

  // Multiplier to scale each member's raw share
  final multiplier = subtotal > 0 ? total / subtotal : 1.0;

  // Per-member summaries
  final Map<String, List<MemberItemShare>> memberItems = {};
  for (final member in members) {
    memberItems[member.id] = [];
  }

  for (final item in items) {
    if (item.splitWeights.isEmpty) continue;
    final totalWeight =
        item.splitWeights.values.fold<double>(0, (sum, w) => sum + w);
    if (totalWeight <= 0) continue;

    for (final entry in item.splitWeights.entries) {
      final memberId = entry.key;
      final weight = entry.value;
      final rawAmount = (weight / totalWeight) * item.price;
      if (memberItems.containsKey(memberId)) {
        memberItems[memberId]!.add(MemberItemShare(item: item, amount: rawAmount));
      }
    }
  }

  final memberSummaries = members.map((member) {
    final memberItemShares = memberItems[member.id] ?? [];
    final rawTotal =
        memberItemShares.fold<double>(0, (sum, s) => sum + s.amount);
    final scaledTotal = rawTotal * multiplier;
    // Scale each item amount too
    final scaledItems = memberItemShares
        .map((s) => MemberItemShare(item: s.item, amount: s.amount * multiplier))
        .toList();
    return MemberSummary(
      member: member,
      total: scaledTotal,
      items: scaledItems,
    );
  }).toList();

  return BillCalculation(
    subtotal: subtotal,
    serviceAmount: serviceAmount,
    vatAmount: vatAmount,
    tipAmount: tipAmount,
    discountAmount: discountAmount,
    total: total,
    memberSummaries: memberSummaries,
  );
}

// ── Simplify debts ────────────────────────────────────────────
/// Calculates who owes whom using per-item paid_by tracking.
///
/// For each member's share of each item:
///   - If the item has a paidBy, the member owes the payer their share amount.
///   - If no item has paidBy, falls back to: first non-external member paid
///     everything, everyone else owes them their share.
///
/// Uses the minimum-transactions algorithm to reduce the number of transfers.
List<DebtTransaction> simplifyDebts(
  List<MemberSummary> summaries,
  List<BillMember> members,
  String? excludeMemberId,
) {
  if (summaries.isEmpty || members.isEmpty) return [];

  // net[memberId] = how much they are owed (positive) or owe (negative)
  final Map<String, double> net = {
    for (final m in members) m.id: 0.0,
  };

  // Check if any item has paidBy set
  final hasPaidBy = summaries.any(
    (s) => s.items.any((i) => i.item.paidBy != null),
  );

  if (hasPaidBy) {
    // Per-item paidBy logic (matches Next.js simplifyDebtsPerItem)
    for (final summary in summaries) {
      for (final itemShare in summary.items) {
        final payerId = itemShare.item.paidBy;
        if (payerId == null) continue;
        // Payer doesn't owe themselves
        if (payerId == summary.member.id) continue;
        // This member owes the payer their share of this item
        net[summary.member.id] = (net[summary.member.id] ?? 0) - itemShare.amount;
        net[payerId] = (net[payerId] ?? 0) + itemShare.amount;
      }
    }
  } else {
    // No paidBy — assume first non-external member paid everything.
    // Everyone else owes them their share.
    final payer = members.firstWhere(
      (m) => !m.isExternal,
      orElse: () => members.first,
    );
    for (final summary in summaries) {
      if (summary.member.id == payer.id) continue;
      if (summary.total <= 0) continue;
      net[summary.member.id] = (net[summary.member.id] ?? 0) - summary.total;
      net[payer.id] = (net[payer.id] ?? 0) + summary.total;
    }
  }

  // Separate into debtors (net < 0) and creditors (net > 0)
  final debtors = <_NetEntry>[];
  final creditors = <_NetEntry>[];

  net.forEach((id, amt) {
    if (id == excludeMemberId) return;
    final member = members.firstWhere((m) => m.id == id,
        orElse: () => members.first);
    if (amt < -0.005) debtors.add(_NetEntry(member, -amt));
    if (amt > 0.005) creditors.add(_NetEntry(member, amt));
  });

  // Minimum-transactions algorithm
  final List<DebtTransaction> debts = [];
  int di = 0, ci = 0;

  while (di < debtors.length && ci < creditors.length) {
    final transfer = debtors[di].amount < creditors[ci].amount
        ? debtors[di].amount
        : creditors[ci].amount;
    if (transfer > 0.005) {
      debts.add(DebtTransaction(
        from: debtors[di].member,
        to: creditors[ci].member,
        amount: transfer,
      ));
    }
    debtors[di].amount -= transfer;
    creditors[ci].amount -= transfer;
    if (debtors[di].amount < 0.005) di++;
    if (creditors[ci].amount < 0.005) ci++;
  }

  return debts;
}

class _NetEntry {
  final BillMember member;
  double amount;
  _NetEntry(this.member, this.amount);
}

// ── Username validation ───────────────────────────────────────
bool isValidUsername(String username) {
  return RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(username);
}

// ── Date formatting ───────────────────────────────────────────
String formatDate(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays == 0) {
    if (diff.inHours == 0) {
      if (diff.inMinutes == 0) return 'เมื่อกี้';
      return '${diff.inMinutes} นาทีที่แล้ว';
    }
    return '${diff.inHours} ชั่วโมงที่แล้ว';
  }
  if (diff.inDays == 1) return 'เมื่อวาน';
  if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
  return DateFormat('d MMM yyyy', 'th').format(date);
}
