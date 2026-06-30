import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import 'bill_status_pill.dart';
import 'member_avatar.dart';

class SharedBillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SharedBillCard({
    super.key,
    required this.bill,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = bill.items.fold(0.0, (s, i) => s + i.price);
    final stripeColor = bill.isCompleted ? AppColors.emerald : AppColors.primary;
    final textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final showActions = onEdit != null || onDelete != null;
    final visibleTags = bill.tags.take(2).toList();
    final extraTags = bill.tags.length > 2 ? bill.tags.length - 2 : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? null : AppColors.shadowCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left color stripe
                Container(width: 5, color: stripeColor),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Emoji icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: stripeColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(bill.emoji ?? '🧾', style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Title + status + meta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bill.title,
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  if (bill.groupName != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                                            : AppColors.primaryFaint,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${bill.groupEmoji ?? '👥'} ${bill.groupName}',
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                  ],
                                  Row(
                                    children: [
                                      BillStatusPill(status: bill.status),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '${bill.items.length} รายการ · ${bill.members.length} คน',
                                          style: GoogleFonts.notoSansThai(fontSize: 11, color: textTertiary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Amount + optional action buttons
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatNumber(total),
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: stripeColor,
                                  ),
                                ),
                                Text(
                                  bill.settings.currency,
                                  style: GoogleFonts.notoSansThai(fontSize: 11, color: textTertiary),
                                ),
                                if (showActions) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (onEdit != null)
                                        GestureDetector(
                                          onTap: onEdit,
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.settings_outlined,
                                              size: 15,
                                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ),
                                      if (onEdit != null && onDelete != null) const SizedBox(width: 6),
                                      if (onDelete != null)
                                        GestureDetector(
                                          onTap: onDelete,
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.red.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.red),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        // Member avatars + date + tags row
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (bill.members.isNotEmpty) ...[
                              MemberAvatarStack(
                                members: bill.members
                                    .map((m) => (
                                          name: m.name.isNotEmpty ? m.name : '?',
                                          color: colorFromHex(m.color),
                                          avatarUrl: m.profile?.avatarUrl,
                                        ))
                                    .toList(),
                                size: 22,
                                maxVisible: 4,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              formatDate(bill.updatedAt),
                              style: GoogleFonts.notoSansThai(fontSize: 10, color: textTertiary),
                            ),
                            const Spacer(),
                            ...visibleTags.map((tag) => Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: GoogleFonts.notoSansThai(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                )),
                            if (extraTags > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  '+$extraTags',
                                  style: GoogleFonts.notoSansThai(fontSize: 10, color: textTertiary),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
