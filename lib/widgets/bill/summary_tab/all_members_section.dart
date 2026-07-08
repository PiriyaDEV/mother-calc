import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';
import 'slip_upload_helper.dart';

class AllMembersSection extends StatelessWidget {
  final BillCalculation calc;
  final Bill bill;
  final BillsStore billsStore;
  final List<DebtTransaction> allDebts;
  final List<BillMember> members;
  final String? currentUserId;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isDark;

  const AllMembersSection({
    super.key,
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
      final l = context.watch<LocaleProvider>();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
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
                    l.t('summary_all_members'),
                    style: GoogleFonts.sarabun(
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
                  l.t('summary_who_owes_whom'),
                  style: GoogleFonts.sarabun(
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
                          name: debt.from.name,
                          color: fromColor,
                          size: 24,
                          avatarUrl: debt.from.profile?.avatarUrl),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          debt.from.name,
                          style: GoogleFonts.sarabun(
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
                          name: debt.to.name,
                          color: toColor,
                          size: 24,
                          avatarUrl: debt.to.profile?.avatarUrl),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          debt.to.name,
                          style: GoogleFonts.sarabun(
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
                        style: GoogleFonts.sarabun(
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
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight),
            ],

            // Per-member breakdown
            ...calc.memberSummaries.map((summary) {
              final member = summary.member;
              final color = colorFromHex(member.color);
              final isPaid = bill.paidMemberIds.contains(member.id);
              final isMe = member.userId == currentUserId;
              final isExternal = member.userId == null;
              final hasPromptPay =
                  member.promptpay != null && member.promptpay!.isNotEmpty;

              return Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.emerald50
                      : (isDark
                          ? AppColors.surfaceDark
                          : AppColors.bgLight),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
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
                            name: member.name,
                            color: color,
                            size: 36,
                            avatarUrl: member.profile?.avatarUrl),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member.name,
                                    style: GoogleFonts.sarabun(
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
                                        label: l.t('member_external_label'), isDark: isDark),
                                  ],
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                     _SmallBadge(
                                        label: l.t('common_you'),
                                        color: AppColors.primary,
                                        isDark: isDark),
                                  ],
                                  if (isPaid) ...[
                                    const SizedBox(width: 4),
                                    _SmallBadge(
                                        label: l.t('summary_paid_label'),
                                        color: AppColors.emerald600,
                                        isDark: isDark),
                                  ],
                                ],
                              ),
                              if (hasPromptPay)
                                Text(
                                  l.t('all_members_promptpay').replaceAll('{pp}', member.promptpay ?? ''),
                                  style: GoogleFonts.sarabun(
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
                          style: GoogleFonts.sarabun(
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
                                    style: GoogleFonts.sarabun(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatNumber(itemShare.amount),
                                  style: GoogleFonts.sarabun(
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
                              await pickSlipAndMarkPaid(
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
                                      ? AppColors.borderDark
                                      : AppColors.borderLight),
                              borderRadius: BorderRadius.circular(AppRadii.full),
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
                                      ? l.t('summary_paid_label')
                                      : (requiresSlip
                                          ? l.t('summary_upload_slip')
                                          : l.t('summary_mark_paid')),
                                  style: GoogleFonts.sarabun(
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
                ? AppColors.borderDark
                : AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Text(
        label,
        style: GoogleFonts.sarabun(
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
