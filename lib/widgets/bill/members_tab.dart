import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/add_member_sheet.dart';
import 'member_tile.dart';

class MembersTab extends StatelessWidget {
  final Bill bill;
  final BillsStore billsStore;
  final BillCalculation calc;
  final bool readOnly;
  final String? currentUserId;
  final Set<String> friendUserIds;

  const MembersTab({
    super.key,
    required this.bill,
    required this.billsStore,
    required this.calc,
    this.readOnly = false,
    this.currentUserId,
    this.friendUserIds = const {},
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort members: current user first → friends → outsiders/external
    final members = [...bill.members]..sort((a, b) {
      int rank(BillMember m) {
        if (m.userId != null && m.userId == currentUserId) return 0;
        if (m.userId != null && friendUserIds.contains(m.userId)) return 1;
        return 2;
      }
      return rank(a).compareTo(rank(b));
    });

    final currency = bill.settings.currency;

    // Build O(1) lookup map once per build — avoids O(n·m) firstWhere per member
    final summaryMap = {
      for (final s in calc.memberSummaries) s.member.id: s,
    };

    // Index 0 = add button (if not readOnly), rest = member tiles
    final headerCount = readOnly ? 0 : 1;
    final itemCount = headerCount + members.length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: itemCount,
      itemBuilder: (ctx, index) {
        if (!readOnly && index == 0) {
          // Add member button
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: true,
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: AddMemberSheet(
                    bill: bill,
                    billsStore: billsStore,
                  ),
                ),
              ),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: Text(
                l.t('members_tab_add'),
                style: GoogleFonts.sarabun(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
            ),
          );
        }

        final memberIndex = index - headerCount;
        final member = members[memberIndex];
        final summary = summaryMap[member.id];
        if (summary == null) return const SizedBox.shrink();

        final isPaid = bill.paidMemberIds.contains(member.id);

        return MemberTile(
          key: ValueKey(member.id),
          member: member,
          summary: summary,
          isPaid: isPaid,
          bill: bill,
          billsStore: billsStore,
          currency: currency,
          readOnly: readOnly,
          currentUserId: currentUserId,
          friendUserIds: friendUserIds,
        );
      },
    );
  }
}
