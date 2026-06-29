import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ── Number formatting ─────────────────────────────────────────
String formatNumber(double value, {int decimals = 2}) {
  if (value == value.truncateToDouble()) {
    // Whole number
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(value);
  }
  final formatter = NumberFormat('#,##0.##', 'en_US');
  return formatter.format(value);
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
Color colorFromHex(String hex) {
  try {
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    } else if (h.length == 8) {
      return Color(int.parse(h, radix: 16));
    }
  } catch (_) {}
  return AppColors.primary;
}

String hexFromColor(Color color) {
  return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
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
    if (item.shares.isEmpty) continue;
    final totalWeight =
        item.shares.values.fold<double>(0, (sum, w) => sum + w);
    if (totalWeight <= 0) continue;

    for (final entry in item.shares.entries) {
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
List<DebtTransaction> simplifyDebts(
  List<MemberSummary> summaries,
  List<BillMember> members,
  String? excludeMemberId,
) {
  // Build per-payer debts from items
  final Map<String, Map<String, double>> owedTo = {};

  for (final summary in summaries) {
    if (summary.member.id == excludeMemberId) continue;
    for (final itemShare in summary.items) {
      final payerId = itemShare.item.paidBy;
      if (payerId == null) continue;
      if (payerId == summary.member.id) continue;

      owedTo.putIfAbsent(summary.member.id, () => {});
      owedTo[summary.member.id]!.update(
        payerId,
        (v) => v + itemShare.amount,
        ifAbsent: () => itemShare.amount,
      );
    }
  }

  final List<DebtTransaction> debts = [];
  for (final fromId in owedTo.keys) {
    final from = members.firstWhere((m) => m.id == fromId,
        orElse: () => members.first);
    for (final toId in owedTo[fromId]!.keys) {
      final amount = owedTo[fromId]![toId]!;
      if (amount < 0.005) continue;
      final to = members.firstWhere((m) => m.id == toId,
          orElse: () => members.first);
      debts.add(DebtTransaction(from: from, to: to, amount: amount));
    }
  }

  return debts;
}

// ── PromptPay QR payload ──────────────────────────────────────
String generatePromptPayPayload(String target, double amount) {
  final cleaned = target.replaceAll('-', '');
  final isPhone = RegExp(r'^0\d{9}$').hasMatch(cleaned);
  final isNationalId = RegExp(r'^\d{13}$').hasMatch(cleaned);

  String targetFormatted = cleaned;
  String targetTag = '01';

  if (isNationalId) {
    targetTag = '02';
  } else if (isPhone) {
    targetFormatted = '66${cleaned.substring(1)}';
  }

  final amountStr = amount.toStringAsFixed(2);

  String tlv(String tag, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$tag$len$value';
  }

  final merchantInfo =
      tlv('00', '01') + tlv('01', 'A000000677010111') + tlv(targetTag, targetFormatted);

  String payload = tlv('00', '01') +
      tlv('01', '12') +
      tlv('29', merchantInfo) +
      tlv('53', '764') +
      (amount > 0 ? tlv('54', amountStr) : '') +
      tlv('58', 'TH') +
      tlv('62', tlv('07', 'KIDTANG'));

  final withCrc = '${payload}6304';
  int crc = 0xFFFF;
  for (int i = 0; i < withCrc.length; i++) {
    crc ^= withCrc.codeUnitAt(i) << 8;
    for (int j = 0; j < 8; j++) {
      crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
    }
  }
  return '$withCrc${(crc & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0')}';
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
