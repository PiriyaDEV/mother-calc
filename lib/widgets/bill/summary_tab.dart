import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'summary_tab/index.dart';

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
  String? _expandedQrMemberId;

  @override
  void initState() {
    super.initState();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final members = widget.bill.members;
    if (members.isNotEmpty) {
      final myMember = members.firstWhere(
        (m) => m.userId == currentUserId,
        orElse: () => members.first,
      );
      _selectedMemberId = myMember.id;
    }
  }

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
      if (payerId == selectedMember.id) continue;
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
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bill = widget.bill;
    final calc = widget.calc;
    final members = widget.bill.members;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isCompleted = bill.isCompleted;

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              l.t('summary_add_members_first'),
              style: GoogleFonts.sarabun(
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

    final selectedDebts = _computeMyDebts(
      selectedMember: selectedMember,
      selectedSummary: selectedSummary,
      members: members,
      calc: calc,
    );

    final allDebts = simplifyDebts(calc.memberSummaries, members, null);

    final paidCount = bill.paidMemberIds.length;
    final allPaid = paidCount == members.length && members.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeroCard(
          calc: calc,
          bill: bill,
          paidCount: paidCount,
          allPaid: allPaid,
          isCompleted: isCompleted,
        ),
        const SizedBox(height: 12),

        BillBreakdownCard(calc: calc, bill: bill, isDark: isDark),
        const SizedBox(height: 12),

        MemberSelector(
          members: members,
          selectedId: _selectedMemberId,
          paidIds: bill.paidMemberIds,
          currentUserId: currentUserId,
          onSelect: (id) => setState(() => _selectedMemberId = id),
        ),
        const SizedBox(height: 12),

        SelectedMemberCard(
          summary: selectedSummary,
          currentUserId: currentUserId,
          currency: bill.settings.currency,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        DebtSection(
          debts: selectedDebts,
          selectedMember: selectedMember,
          currentUserId: currentUserId,
          bill: bill,
          billsStore: widget.billsStore,
          currency: bill.settings.currency,
          isDark: isDark,
          expandedQrMemberId: _expandedQrMemberId,
          onToggleQr: (id) => setState(
              () => _expandedQrMemberId =
                  _expandedQrMemberId == id ? null : id),
        ),
        const SizedBox(height: 12),

        AllMembersSection(
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
