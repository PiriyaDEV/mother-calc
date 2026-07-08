import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';

class StatsRow extends StatelessWidget {
  final int itemCount;
  final int memberCount;
  final double avgPerPerson;

  const StatsRow({
    super.key,
    required this.itemCount,
    required this.memberCount,
    required this.avgPerPerson,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: '🧾',
            value: itemCount.toString(),
            label: l.t('analytics_items_label'),
            bgColor: AppColors.primaryLight,
            borderColor: AppColors.borderLight,
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            emoji: '👥',
            value: memberCount.toString(),
            label: l.t('analytics_members_label'),
            bgColor: AppColors.primaryLight,
            borderColor: AppColors.borderLight,
            valueColor: AppColors.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            emoji: '💰',
            value: formatNumber(avgPerPerson, decimals: 0),
            label: l.t('analytics_avg_per_person_short'),
            bgColor: AppColors.primaryLight,
            borderColor: AppColors.borderLight,
            valueColor: AppColors.emerald500,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color valueColor;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.sarabun(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.sarabun(
              fontSize: 11,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
