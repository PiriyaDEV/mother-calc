import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/emoji_text.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';

class BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final String? currentUserId;
  final Set<String> friendUserIds;

  const BillCard({
    super.key,
    required this.bill,
    required this.onTap,
    this.currentUserId,
    this.friendUserIds = const {},
  });

  List<BillMember> get _sortedMembers {
    if (currentUserId == null && friendUserIds.isEmpty) return bill.members;
    return [...bill.members]..sort((a, b) {
        int rank(BillMember m) {
          if (m.userId != null && m.userId == currentUserId) return 0;
          if (m.userId != null && friendUserIds.contains(m.userId)) return 1;
          return 2;
        }
        return rank(a).compareTo(rank(b));
      });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calc = calculateBill(bill);
    final currency = bill.settings.currency;
    final members = _sortedMembers;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: isDark ? null : AppColors.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji / icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryBlue.withValues(alpha: 0.15)
                        : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: EmojiText(bill.emoji ?? '🧾', fontSize: 22),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: GoogleFonts.sarabun(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDate(bill.updatedAt ?? bill.createdAt),
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
                      formatNumber(calc.total),
                      style: GoogleFonts.sarabun(
                        fontSize: 16,
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
              ],
            ),
            if (members.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  // Member avatars
                  MemberAvatarStack(
                    members: members
                        .map((m) => (
                              name: m.name,
                              color: colorFromHex(m.color),
                              avatarUrl: m.profile?.avatarUrl,
                            ))
                        .toList(),
                    size: 24,
                    maxVisible: 5,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${bill.members.length} คน',
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const Spacer(),
                  // Status pill
                  _BillStatusBadge(status: bill.status),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _BillStatusBadge(status: bill.status),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BillStatusBadge extends StatelessWidget {
  final String status;

  const _BillStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final Color bgColor;
    final Color dotColor;
    final Color textColor;
    final String label;

    if (status == 'completed') {
      bgColor = AppColors.emeraldLight;
      dotColor = AppColors.emerald;
      textColor = AppColors.emeraldText;
      label = l.t('bill_status_completed');
    } else if (status == 'pending_payment') {
      bgColor = AppColors.amberLight;
      dotColor = AppColors.amber;
      textColor = AppColors.amberText;
      label = l.t('bill_status_pending');
    } else {
      bgColor = AppColors.borderLight;
      dotColor = AppColors.textTertiaryLight;
      textColor = AppColors.textSecondaryLight;
      label = l.t('bill_status_draft');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: GoogleFonts.sarabun(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
