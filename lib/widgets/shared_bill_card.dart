import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import 'bill_status_pill.dart';
import 'member_avatar.dart';
import 'tag_chip.dart';

class SharedBillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;

  const SharedBillCard({
    super.key,
    required this.bill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = bill.items.fold(0.0, (s, i) => s + i.price);
    final stripeColor = bill.isCompleted ? AppColors.emerald : AppColors.primary;
    final textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final firstTag = bill.tags.isNotEmpty ? bill.tags.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: isDark ? null : AppColors.shadowCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left color stripe
                Container(width: 4, color: stripeColor),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top: emoji + title + amount
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: stripeColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                              ),
                              child: Center(
                                child: Text(bill.emoji ?? '🧾', style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    bill.title,
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  if (bill.groupName != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${bill.groupEmoji ?? '👥'} ${bill.groupName}',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formatNumber(total),
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: stripeColor,
                                  ),
                                ),
                                Text(
                                  bill.settings.currency,
                                  style: GoogleFonts.notoSansThai(fontSize: 10, color: textTertiary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Bottom: avatars + date + status + 1 tag
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
                                size: 20,
                                maxVisible: 4,
                              ),
                              const SizedBox(width: 7),
                            ],
                            Text(
                              formatDate(bill.updatedAt),
                              style: GoogleFonts.notoSansThai(fontSize: 10, color: textTertiary),
                            ),
                            const Spacer(),
                            BillStatusPill(status: bill.status),
                            if (firstTag != null) ...[
                              const SizedBox(width: 5),
                              TagChip(tag: firstTag, fontSize: 10, borderRadius: 6),
                            ],
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
