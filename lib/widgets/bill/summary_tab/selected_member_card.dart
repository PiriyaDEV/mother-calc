import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';

class SelectedMemberCard extends StatelessWidget {
  final MemberSummary summary;
  final String? currentUserId;
  final String currency;
  final bool isDark;

  const SelectedMemberCard({
    super.key,
    required this.summary,
    required this.currentUserId,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final member = summary.member;
    final color = colorFromHex(member.color);
    final isMe = member.userId == currentUserId;
    final isExternal = member.userId == null;
    final emoji = getTotalEmoji(summary.total);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
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
                MemberAvatar(
                    name: member.name,
                    color: color,
                    size: 44,
                    avatarUrl: member.profile?.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.name,
                            style: GoogleFonts.sarabun(
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
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                                borderRadius: BorderRadius.circular(AppRadii.xs),
                              ),
                              child: Text(
                                l.t('selected_member_external'),
                                style: GoogleFonts.sarabun(
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
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(AppRadii.xs),
                              ),
                              child: Text(
                                l.t('selected_member_you'),
                                style: GoogleFonts.sarabun(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
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
                          l.t('selected_member_promptpay').replaceAll('{pp}', member.promptpay ?? ''),
                          style: GoogleFonts.sarabun(
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
                      style: GoogleFonts.sarabun(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      l.t('selected_member_share_title').replaceAll('{emoji}', emoji).replaceAll('{name}', isMe ? l.t('selected_member_share_me') : member.name),
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
          ),

          // Items breakdown
          if (summary.items.isNotEmpty) ...[
            Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                l.t('selected_member_items_ordered'),
                style: GoogleFonts.sarabun(
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
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      Text(
                        '${formatNumber(itemShare.amount)} $currency',
                        style: GoogleFonts.sarabun(
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
                    l.t('selected_member_total_with_tax'),
                    style: GoogleFonts.sarabun(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    '${formatNumber(summary.total)} $currency',
                    style: GoogleFonts.sarabun(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                       color: AppColors.primary,
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
