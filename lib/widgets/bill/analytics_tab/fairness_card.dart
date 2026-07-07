import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'member_total.dart';

class FairnessCard extends StatelessWidget {
  final MemberTotal biggestPayer;
  final MemberTotal smallestPayer;
  final double avgPerPerson;
  final bool isDark;

  const FairnessCard({
    super.key,
    required this.biggestPayer,
    required this.smallestPayer,
    required this.avgPerPerson,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ratio =
        biggestPayer.total / (smallestPayer.total > 0 ? smallestPayer.total : 1);
    final String fairnessEmoji;
    final Color fairnessColor;
    if (ratio > 3.0) {
      fairnessEmoji = '😬';
      fairnessColor = AppColors.red;
    } else if (ratio > 1.5) {
      fairnessEmoji = '🤔';
      fairnessColor = AppColors.amber500;
    } else {
      fairnessEmoji = '😊';
      fairnessColor = AppColors.emerald500;
    }
    final ratioText = '${ratio.toStringAsFixed(1)}x';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'ความเท่าเทียม',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: fairnessColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fairnessEmoji,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      ratioText,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fairnessColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FairnessPersonCol(
                  label: 'จ่ายน้อยสุด',
                  name: smallestPayer.member.name,
                  amount: smallestPayer.total,
                  color: AppColors.emerald500,
                  isDark: isDark,
                  align: CrossAxisAlignment.start,
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ],
              ),
              Expanded(
                child: FairnessPersonCol(
                  label: 'จ่ายเยอะสุด',
                  name: biggestPayer.member.name,
                  amount: biggestPayer.total,
                  color: AppColors.amber500,
                  isDark: isDark,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เฉลี่ยต่อคน',
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                '${formatNumber(avgPerPerson)} บาท',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FairnessPersonCol extends StatelessWidget {
  final String label;
  final String name;
  final double amount;
  final Color color;
  final bool isDark;
  final CrossAxisAlignment align;

  const FairnessPersonCol({
    super.key,
    required this.label,
    required this.name,
    required this.amount,
    required this.color,
    required this.isDark,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          Text(
            '${formatNumber(amount)} บาท',
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
