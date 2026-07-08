import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';
import 'member_form_sheet.dart';

class MemberTile extends StatelessWidget {
  final BillMember member;
  final MemberSummary summary;
  final bool isPaid;
  final Bill bill;
  final BillsStore billsStore;
  final String currency;
  final bool readOnly;
  final String? currentUserId;
  final Set<String> friendUserIds;

  const MemberTile({
    super.key,
    required this.member,
    required this.summary,
    required this.isPaid,
    required this.bill,
    required this.billsStore,
    required this.currency,
    this.readOnly = false,
    this.currentUserId,
    this.friendUserIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = colorFromHex(member.color);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: readOnly || !member.isExternal
            ? null
            : () => showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: MemberFormSheet(
                      bill: bill,
                      billsStore: billsStore,
                      editMember: member,
                    ),
                  ),
                ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Row(
            children: [
              MemberAvatar(
                name: member.name,
                color: color,
                size: 40,
                avatarUrl: member.profile?.avatarUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.sarabun(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        ..._buildMemberPill(context),
                      ],
                    ),
                    Text(
                      '${summary.items.length} รายการ',
                      style: GoogleFonts.sarabun(
                        fontSize: 12,
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
                    formatNumber(summary.total),
                    style: GoogleFonts.sarabun(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    currency,
                    style: GoogleFonts.sarabun(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Paid toggle
              GestureDetector(
                onTap: () async {
                  await billsStore.toggleMemberPaid(bill.id, member.id);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppColors.emerald
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.neutral100),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPaid ? Icons.check_rounded : Icons.circle_outlined,
                    color: isPaid
                        ? Colors.white
                        : (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMemberPill(BuildContext context) {
    final l = context.read<LocaleProvider>();
    final String label;
    final Color color;

    if (member.isExternal) {
      label = l.t('bill_member_external');
      color = AppColors.neutral600;
    } else if (member.userId != null && member.userId == currentUserId) {
      label = l.t('bill_member_me');
      color = AppColors.primary;
    } else if (member.userId != null && friendUserIds.contains(member.userId)) {
      label = l.t('bill_member_friend');
      color = AppColors.emerald;
    } else {
      return [];
    }

    return [
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        child: Text(
          label,
          style: GoogleFonts.sarabun(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    ];
  }
}
