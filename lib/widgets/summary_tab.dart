import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../stores/bills_store.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import 'member_avatar.dart';

// ── Slip upload + confirm helper ──────────────────────────────
Future<void> _pickSlipAndMarkPaid(
  BuildContext context, {
  required BillsStore billsStore,
  required Bill bill,
  required String memberId,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final source = await showDialog<ImageSource>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'อัพโหลดสลิปการโอน',
              style: GoogleFonts.notoSansThai(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เลือกหลักฐานการโอนเงิน เพื่อยืนยันการชำระ',
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.blue400),
              title: Text('เลือกจากคลังรูป', style: GoogleFonts.notoSansThai(fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.blue400),
              title: Text('ถ่ายภาพ', style: GoogleFonts.notoSansThai(fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return;
  if (!context.mounted) return;

  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: source,
    maxWidth: 1920,
    imageQuality: 85,
  );
  if (image == null) return;
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'ยืนยันการชำระเงิน',
        style: GoogleFonts.notoSansThai(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                // dart:io File isn't supported on web — image.path is a blob URL there.
                ? Image.network(
                    image.path,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(image.path),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            'ยืนยันว่าคุณได้ทำการโอนเงินแล้ว?',
            style: GoogleFonts.notoSansThai(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('ยกเลิก', style: GoogleFonts.notoSansThai()),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.emerald500),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('ยืนยัน', style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  await billsStore.toggleMemberPaid(bill.id, memberId);
}

class SummaryTab extends StatefulWidget {
  final Bill bill;
  final BillsStore billsStore;
  final BillCalculation calc;

  const SummaryTab({
    super.key,
    required this.bill,
    required this.billsStore,
    required this.calc,
  });

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  String? _selectedMemberId;
  bool _allMembersExpanded = false;
  String? _expandedQrMemberId; // for debt card QR

  @override
  void initState() {
    super.initState();
    // Default select current user's member, or first member
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;
    final members = widget.bill.members;
    if (members.isNotEmpty) {
      final myMember = members.firstWhere(
        (m) => m.userId == currentUserId,
        orElse: () => members.first,
      );
      _selectedMemberId = myMember.id;
    }
  }

  /// Compute per-payer debts for the selected member (no simplification).
  /// Matches Next.js myDebts logic: group by payer, sum amounts, no greedy simplification.
  /// Note: itemShare.amount in summary.items is already scaled (tax/SC applied).
  List<DebtTransaction> _computeMyDebts({
    required BillMember selectedMember,
    required MemberSummary selectedSummary,
    required List<BillMember> members,
    required BillCalculation calc,
  }) {
    final Map<String, double> owedTo = {};

    for (final itemShare in selectedSummary.items) {
      final payerId = itemShare.item.paidBy;
      if (payerId == null) continue;
      if (payerId == selectedMember.id) continue; // don't owe yourself
      // itemShare.amount is already scaled (includes VAT/SC multiplier)
      owedTo[payerId] = (owedTo[payerId] ?? 0) + itemShare.amount;
    }

    final result = <DebtTransaction>[];
    for (final entry in owedTo.entries) {
      if (entry.value < 0.005) continue;
      final payer = members.where((m) => m.id == entry.key).firstOrNull;
      if (payer == null) continue;
      result.add(DebtTransaction(
        from: selectedMember,
        to: payer,
        amount: entry.value,
      ));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bill = widget.bill;
    final calc = widget.calc;
    final members = widget.bill.members;
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;
    final isCompleted = bill.isCompleted;

    // Empty state
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'เพิ่มสมาชิกและรายการก่อน',
              style: GoogleFonts.notoSansThai(
                fontSize: 15,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    final selectedMember = _selectedMemberId != null
        ? members.firstWhere((m) => m.id == _selectedMemberId,
            orElse: () => members.first)
        : members.first;

    final selectedSummary = calc.memberSummaries.firstWhere(
      (s) => s.member.id == selectedMember.id,
      orElse: () =>
          MemberSummary(member: selectedMember, total: 0, items: []),
    );

    // Debts for selected member — per-payer direct (no simplification), matches Next.js myDebts
    final selectedDebts = _computeMyDebts(
      selectedMember: selectedMember,
      selectedSummary: selectedSummary,
      members: members,
      calc: calc,
    );

    // All debts (simplified) for the overview section
    final allDebts = simplifyDebts(calc.memberSummaries, members, null);

    final paidCount = bill.paidMemberIds.length;
    final allPaid = paidCount == members.length && members.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Hero Card ──────────────────────────────────────────
        _HeroCard(
          calc: calc,
          bill: bill,
          paidCount: paidCount,
          allPaid: allPaid,
          isCompleted: isCompleted,
        ),
        const SizedBox(height: 12),

        // ── Bill Breakdown ─────────────────────────────────────
        _BillBreakdownCard(calc: calc, bill: bill, isDark: isDark),
        const SizedBox(height: 12),

        // ── Member Selector ────────────────────────────────────
        _MemberSelector(
          members: members,
          selectedId: _selectedMemberId,
          paidIds: bill.paidMemberIds,
          currentUserId: currentUserId,
          onSelect: (id) => setState(() => _selectedMemberId = id),
        ),
        const SizedBox(height: 12),

        // ── Selected Member Detail ─────────────────────────────
        _SelectedMemberCard(
          summary: selectedSummary,
          currentUserId: currentUserId,
          currency: bill.settings.currency,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // ── Debt Arrows ────────────────────────────────────────
        _DebtSection(
          debts: selectedDebts,
          selectedMember: selectedMember,
          currentUserId: currentUserId,
          bill: bill,
          billsStore: widget.billsStore,
          currency: bill.settings.currency,
          isDark: isDark,
          expandedQrMemberId: _expandedQrMemberId,
          onToggleQr: (id) =>
              setState(() => _expandedQrMemberId =
                  _expandedQrMemberId == id ? null : id),
        ),
        const SizedBox(height: 12),

        // ── All Members Section ────────────────────────────────
        _AllMembersSection(
          calc: calc,
          bill: bill,
          billsStore: widget.billsStore,
          allDebts: allDebts,
          members: members,
          currentUserId: currentUserId,
          isExpanded: _allMembersExpanded,
          onToggle: () =>
              setState(() => _allMembersExpanded = !_allMembersExpanded),
          isDark: isDark,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final BillCalculation calc;
  final Bill bill;
  final int paidCount;
  final bool allPaid;
  final bool isCompleted;

  const _HeroCard({
    required this.calc,
    required this.bill,
    required this.paidCount,
    required this.allPaid,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final settings = bill.settings;
    final memberCount = bill.members.isNotEmpty
        ? bill.members.length
        : 1;
    final emoji = getTotalEmoji(calc.total);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue400, AppColors.blue500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ยอดรวมทั้งสิ้น',
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${formatNumber(calc.total)} ${settings.currency}',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(emoji, style: const TextStyle(fontSize: 28)),
            ],
          ),
          if (settings.isService) ...[
            const SizedBox(height: 4),
            Text(
              'รวม Service Charge ${settings.serviceCharge.toStringAsFixed(0)}%',
              style: GoogleFonts.notoSansThai(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (settings.isVat) ...[
            const SizedBox(height: 2),
            Text(
              'รวม VAT ${settings.vat.toStringAsFixed(0)}%',
              style: GoogleFonts.notoSansThai(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (isCompleted) ...[
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'สถานะการชำระ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '$paidCount/$memberCount คน',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: memberCount > 0 ? paidCount / memberCount : 0,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            if (allPaid) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'ทุกคนจ่ายแล้ว!',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Bill Breakdown Card ───────────────────────────────────────
class _BillBreakdownCard extends StatelessWidget {
  final BillCalculation calc;
  final Bill bill;
  final bool isDark;

  const _BillBreakdownCard({
    required this.calc,
    required this.bill,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final settings = bill.settings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รายละเอียดบิล',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          _BreakdownRow(
            label: 'ยอดรวมสินค้า',
            value: calc.subtotal,
            currency: settings.currency,
            isDark: isDark,
          ),
          if (settings.isService && calc.serviceAmount > 0)
            _BreakdownRow(
              label:
                  'Service Charge (${settings.serviceCharge.toStringAsFixed(0)}%)',
              value: calc.serviceAmount,
              currency: settings.currency,
              isDark: isDark,
            ),
          if (settings.isVat && calc.vatAmount > 0)
            _BreakdownRow(
              label: 'VAT (${settings.vat.toStringAsFixed(0)}%)',
              value: calc.vatAmount,
              currency: settings.currency,
              isDark: isDark,
            ),
          if (calc.tipAmount > 0)
            _BreakdownRow(
              label: 'ทิป',
              value: calc.tipAmount,
              currency: settings.currency,
              isDark: isDark,
            ),
          if (calc.discountAmount > 0)
            _BreakdownRow(
              label: 'ส่วนลด',
              value: -calc.discountAmount,
              currency: settings.currency,
              isDark: isDark,
              isDiscount: true,
            ),
          Divider(
              height: 16,
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รวมทั้งสิ้น',
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '฿${formatNumber(calc.total)}',
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final bool isDark;
  final bool isDiscount;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.currency,
    required this.isDark,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            '฿${formatNumber(value.abs())}',
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: isDiscount
                  ? AppColors.emerald600
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Member Selector ───────────────────────────────────────────
class _MemberSelector extends StatelessWidget {
  final List<BillMember> members;
  final String? selectedId;
  final List<String> paidIds;
  final String? currentUserId;
  final ValueChanged<String> onSelect;

  const _MemberSelector({
    required this.members,
    required this.selectedId,
    required this.paidIds,
    required this.currentUserId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ดูสรุปของ',
          style: GoogleFonts.notoSansThai(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: members.map((m) {
              final isSelected = selectedId == m.id;
              final isPaid = paidIds.contains(m.id);
              final isMe = m.userId == currentUserId;
              final color = colorFromHex(m.color);

              Color bgColor;
              Color textColor;
              Color? borderColor;

              if (isSelected) {
                bgColor = AppColors.blue400;
                textColor = Colors.white;
                borderColor = null;
              } else if (isPaid) {
                bgColor = AppColors.emerald50;
                textColor = AppColors.emerald700;
                borderColor = AppColors.emerald200;
              } else {
                bgColor = isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF3F4F6);
                textColor = isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight;
                borderColor = null;
              }

              return GestureDetector(
                onTap: () => onSelect(m.id),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: borderColor != null
                        ? Border.all(color: borderColor)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MemberAvatar(
                        name: m.name,
                        color: isSelected ? Colors.white.withValues(alpha: 0.9) : color,
                        size: 22,
                        avatarUrl: m.profile?.avatarUrl,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m.name,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : AppColors.blue400.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'คุณ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.blue400,
                            ),
                          ),
                        ),
                      ],
                      if (isPaid && !isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_rounded,
                            size: 14, color: AppColors.emerald600),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Selected Member Detail Card ───────────────────────────────
class _SelectedMemberCard extends StatelessWidget {
  final MemberSummary summary;
  final String? currentUserId;
  final String currency;
  final bool isDark;

  const _SelectedMemberCard({
    required this.summary,
    required this.currentUserId,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final member = summary.member;
    final color = colorFromHex(member.color);
    final isMe = member.userId == currentUserId;
    final isExternal = member.userId == null;
    final emoji = getTotalEmoji(summary.total);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MemberAvatar(name: member.name, color: color, size: 44, avatarUrl: member.profile?.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.name,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          if (isExternal) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ภายนอก',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 10,
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                ),
                              ),
                            ),
                          ],
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.blue400.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'คุณ',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blue400,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (member.promptpay != null &&
                          member.promptpay!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'พร้อมเพย์: ${member.promptpay}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatNumber(summary.total),
                      style: GoogleFonts.notoSansThai(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '$emoji ส่วนของ${isMe ? 'ฉัน' : member.name}',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items breakdown
          if (summary.items.isNotEmpty) ...[
            Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                'รายการที่สั่ง',
                style: GoogleFonts.notoSansThai(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ),
            ...summary.items.map((itemShare) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          itemShare.item.name,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      Text(
                        '${formatNumber(itemShare.amount)} $currency',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )),
            Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รวม (รวม VAT/SC)',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    '${formatNumber(summary.total)} $currency',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Debt Section ──────────────────────────────────────────────
class _DebtSection extends StatelessWidget {
  final List<DebtTransaction> debts;
  final BillMember selectedMember;
  final String? currentUserId;
  final Bill bill;
  final BillsStore billsStore;
  final String currency;
  final bool isDark;
  final String? expandedQrMemberId;
  final ValueChanged<String> onToggleQr;

  const _DebtSection({
    required this.debts,
    required this.selectedMember,
    required this.currentUserId,
    required this.bill,
    required this.billsStore,
    required this.currency,
    required this.isDark,
    required this.expandedQrMemberId,
    required this.onToggleQr,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = selectedMember.userId == currentUserId;
    final title = isMe
        ? 'ฉันต้องโอนให้'
        : '${selectedMember.name} ต้องโอนให้';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        if (debts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.emerald200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.emerald600, size: 18),
                const SizedBox(width: 8),
                Text(
                  isMe
                      ? 'คุณไม่ต้องโอนให้ใคร'
                      : '${selectedMember.name} ไม่ต้องโอนให้ใคร',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    color: AppColors.emerald700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...debts.map((debt) => _DebtCard(
                debt: debt,
                bill: bill,
                billsStore: billsStore,
                currency: currency,
                isDark: isDark,
                isQrExpanded: expandedQrMemberId == debt.to.id,
                onToggleQr: () => onToggleQr(debt.to.id),
              )),
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  final DebtTransaction debt;
  final Bill bill;
  final BillsStore billsStore;
  final String currency;
  final bool isDark;
  final bool isQrExpanded;
  final VoidCallback onToggleQr;

  const _DebtCard({
    required this.debt,
    required this.bill,
    required this.billsStore,
    required this.currency,
    required this.isDark,
    required this.isQrExpanded,
    required this.onToggleQr,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = bill.paidMemberIds.contains(debt.from.id);
    final fromColor = colorFromHex(debt.from.color);
    final toColor = colorFromHex(debt.to.color);
    final hasPromptPay = debt.to.promptpay != null &&
        debt.to.promptpay!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isPaid
            ? AppColors.emerald50
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid
              ? AppColors.emerald200
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // From → To avatars
                MemberAvatar(name: debt.from.name, color: fromColor, size: 32, avatarUrl: debt.from.profile?.avatarUrl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
                MemberAvatar(name: debt.to.name, color: toColor, size: 32, avatarUrl: debt.to.profile?.avatarUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.to.name,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (hasPromptPay)
                        Text(
                          'พร้อมเพย์: ${debt.to.promptpay}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatNumber(debt.amount),
                      style: GoogleFonts.notoSansThai(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isPaid
                            ? AppColors.emerald600
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                        decoration: isPaid
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      currency,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
                if (hasPromptPay) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onToggleQr,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isQrExpanded
                            ? AppColors.blue400.withValues(alpha: 0.1)
                            : (isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.qr_code_rounded,
                        size: 18,
                        color: isQrExpanded
                            ? AppColors.blue400
                            : (isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // QR expand
          if (isQrExpanded && hasPromptPay) ...[
            Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.network(
                      'https://promptpay.io/${debt.to.promptpay}/${debt.amount.toStringAsFixed(2)}.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 180,
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const SizedBox(
                        width: 180,
                        height: 180,
                        child: Center(
                          child: Icon(Icons.qr_code_rounded, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'สแกนโอนให้ ${debt.to.name}',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    debt.to.promptpay!,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Paid toggle (isCompleted or pending_payment)
          if (bill.isCompleted || bill.status == 'pending_payment') ...[
            Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isPaid
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isPaid ? AppColors.emerald500 : AppColors.textTertiaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPaid ? 'จ่ายแล้ว' : 'ยังไม่ได้จ่าย',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      color: isPaid
                          ? AppColors.emerald600
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () async {
                        if (!isPaid) {
                          await _pickSlipAndMarkPaid(
                            ctx,
                            billsStore: billsStore,
                            bill: bill,
                            memberId: debt.from.id,
                          );
                        } else {
                          await billsStore.toggleMemberPaid(
                              bill.id, debt.from.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? (isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFF3F4F6))
                              : AppColors.emerald500,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isPaid)
                              const Icon(Icons.upload_rounded,
                                  size: 14, color: Colors.white),
                            if (isPaid)
                              Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              isPaid ? 'ยกเลิก' : 'อัพโหลดสลิป',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPaid
                                    ? (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── All Members Section ───────────────────────────────────────
class _AllMembersSection extends StatelessWidget {
  final BillCalculation calc;
  final Bill bill;
  final BillsStore billsStore;
  final List<DebtTransaction> allDebts;
  final List<BillMember> members;
  final String? currentUserId;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isDark;

  const _AllMembersSection({
    required this.calc,
    required this.bill,
    required this.billsStore,
    required this.allDebts,
    required this.members,
    required this.currentUserId,
    required this.isExpanded,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          // Header toggle
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'สรุปทุกคน',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight),

            // Debt arrows overview
            if (allDebts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'ใครโอนให้ใคร',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ),
              ...allDebts.map((debt) {
                final isPaid = bill.paidMemberIds.contains(debt.from.id);
                final fromColor = colorFromHex(debt.from.color);
                final toColor = colorFromHex(debt.to.color);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                        MemberAvatar(
                            name: debt.from.name, color: fromColor, size: 24, avatarUrl: debt.from.profile?.avatarUrl),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          debt.from.name,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            decoration: isPaid
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded,
                          size: 12,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight),
                      const SizedBox(width: 4),
                      MemberAvatar(
                          name: debt.to.name, color: toColor, size: 24, avatarUrl: debt.to.profile?.avatarUrl),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          debt.to.name,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${formatNumber(debt.amount)} ${bill.settings.currency}',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPaid
                              ? AppColors.emerald600
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                          decoration: isPaid
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (isPaid) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_rounded,
                            size: 14, color: AppColors.emerald500),
                      ],
                    ],
                  ),
                );
              }),
              Divider(
                  height: 16,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ],

            // Per-member breakdown
            ...calc.memberSummaries.map((summary) {
              final member = summary.member;
              final color = colorFromHex(member.color);
              final isPaid = bill.paidMemberIds.contains(member.id);
              final isMe = member.userId == currentUserId;
              final isExternal = member.userId == null;
              final hasPromptPay = member.promptpay != null &&
                  member.promptpay!.isNotEmpty;

              return Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.emerald50
                      : (isDark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFF9FAFB)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaid
                        ? AppColors.emerald100
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        MemberAvatar(
                            name: member.name, color: color, size: 36, avatarUrl: member.profile?.avatarUrl),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member.name,
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  if (isExternal) ...[
                                    const SizedBox(width: 4),
                                    _SmallBadge(
                                        label: 'ภายนอก',
                                        isDark: isDark),
                                  ],
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    _SmallBadge(
                                        label: 'คุณ',
                                        color: AppColors.blue400,
                                        isDark: isDark),
                                  ],
                                  if (isPaid) ...[
                                    const SizedBox(width: 4),
                                    _SmallBadge(
                                        label: 'จ่ายแล้ว',
                                        color: AppColors.emerald600,
                                        isDark: isDark),
                                  ],
                                ],
                              ),
                              if (hasPromptPay)
                                Text(
                                  'พร้อมเพย์: ${member.promptpay}',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${formatNumber(summary.total)} ${bill.settings.currency}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? AppColors.emerald600
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                    // Item breakdown
                    if (summary.items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...summary.items.map((itemShare) => Padding(
                            padding: const EdgeInsets.only(
                                left: 46, bottom: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '├ ${itemShare.item.name}',
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatNumber(itemShare.amount),
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    // Paid toggle (isCompleted only)
                    if (bill.isCompleted) ...[
                      const SizedBox(height: 8),
                      Builder(builder: (ctx) {
                        final requiresSlip = allDebts.any((d) =>
                            d.from.id == member.id &&
                            (d.to.promptpay?.isNotEmpty ?? false));
                        return GestureDetector(
                          onTap: () async {
                            if (!isPaid && requiresSlip) {
                              await _pickSlipAndMarkPaid(
                                ctx,
                                billsStore: billsStore,
                                bill: bill,
                                memberId: member.id,
                              );
                            } else {
                              await billsStore.toggleMemberPaid(
                                  bill.id, member.id);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? AppColors.emerald500
                                  : (isDark
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPaid)
                                  const Icon(Icons.check_rounded,
                                      size: 14, color: Colors.white),
                                if (!isPaid && requiresSlip)
                                  Icon(Icons.upload_rounded,
                                      size: 14,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                                if (!isPaid && !requiresSlip)
                                  Icon(Icons.circle_outlined,
                                      size: 14,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  isPaid
                                      ? 'จ่ายแล้ว'
                                      : (requiresSlip
                                          ? 'อัพโหลดสลิป'
                                          : 'ทำเครื่องหมายว่าจ่ายแล้ว'),
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isPaid
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isDark;

  const _SmallBadge({
    required this.label,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: c != null
            ? c.withValues(alpha: 0.12)
            : (isDark
                ? const Color(0xFF374151)
                : const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansThai(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: c ??
              (isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight),
        ),
      ),
    );
  }
}
