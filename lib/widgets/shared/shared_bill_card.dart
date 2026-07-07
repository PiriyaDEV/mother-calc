import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';

class SharedBillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;

  const SharedBillCard({super.key, required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = bill.total;
    final isCompleted = bill.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.neutral100,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF2D5BFF).withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            // ── Emoji icon ──────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.accentIceDark : AppColors.accentIce,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Center(
                child: Text(
                  bill.emoji ?? '🧾',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Title + meta ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.neutral900Dark
                          : AppColors.neutral900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Date
                      Text(
                        formatDate(bill.updatedAt ?? bill.createdAt),
                        style: GoogleFonts.notoSansThai(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.neutral400Dark
                              : AppColors.neutral400,
                        ),
                      ),
                      // Member count
                      if (bill.members.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.neutral400Dark
                                : AppColors.neutral400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        MemberAvatarStack(
                          members: bill.members
                              .take(3)
                              .map((m) => (
                                    name: m.name,
                                    color: colorFromHex(m.color),
                                    avatarUrl: m.profile?.avatarUrl,
                                  ))
                              .toList(),
                          size: 18,
                          maxVisible: 3,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${bill.members.length} คน',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.neutral400Dark
                                : AppColors.neutral400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Amount + status ─────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '฿${formatNumber(total)}',
                  style: GoogleFonts.anuphan(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.neutral900Dark
                        : AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.emeraldLight
                        : AppColors.amberLight,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.emerald
                              : AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompleted ? 'เสร็จแล้ว' : 'ดำเนินการ',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? AppColors.emeraldText
                              : AppColors.amberText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
