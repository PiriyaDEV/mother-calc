import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';
import 'member_total.dart';

class BiggestSpenderCard extends StatelessWidget {
  final MemberTotal payer;
  final double total;

  const BiggestSpenderCard({
    super.key,
    required this.payer,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final color = colorFromHex(payer.member.color);
    final pct = total > 0 ? (payer.total / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amberFaint,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amber500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('analytics_biggest_spender'),
                  style: GoogleFonts.sarabun(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.amber600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    MemberAvatar(
                      name: payer.member.name,
                      color: color,
                      size: 20,
                      avatarUrl: payer.member.profile?.avatarUrl,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      payer.member.name,
                      style: GoogleFonts.sarabun(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${payer.itemCount} รายการ',
                  style: GoogleFonts.sarabun(
                      fontSize: 11, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatNumber(payer.total)} บาท',
                style: GoogleFonts.sarabun(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amber600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Text(
                  '$pct% ของบิล',
                  style: GoogleFonts.sarabun(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.amber600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
