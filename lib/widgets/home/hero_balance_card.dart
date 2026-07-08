import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';

/// Clubhouse-style hero card: clean white surface, large number,
/// subtle blue accent border, no heavy gradients.
class HeroBalanceCard extends StatelessWidget {
  const HeroBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Selector2<BillsStore, GroupsStore, (BillAggregateStats?, int, bool)>(
      selector: (_, billsStore, groupsStore) => (
        billsStore.stats,
        groupsStore.groupsCount ?? 0,
        billsStore.statsLoading && billsStore.stats == null,
      ),
      builder: (context, data, _) {
        final (stats, groupsCount, dataLoading) = data;
        final grandTotal = stats?.grandTotal ?? 0;
        final totalItems = stats?.totalItems ?? 0;
        final totalBills = stats?.totalCount ?? 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: isDark
                  ? null
                  : [AppShadows.card],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label row
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.t('home_stats_title'),
                      style: GoogleFonts.sarabun(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Big number
                if (dataLoading)
                  Container(
                    width: 140,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.bgSubtle,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  )
                else
                  Text(
                    '฿${formatNumber(grandTotal)}',
                    style: GoogleFonts.sarabun(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Stats row — pill chips
                if (!dataLoading)
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_outline_rounded,
                        label: '$groupsCount กลุ่ม',
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatChip(
                        icon: Icons.receipt_long_outlined,
                        label: '$totalBills บิล',
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatChip(
                        icon: Icons.format_list_bulleted_rounded,
                        label: '$totalItems รายการ',
                        isDark: isDark,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : AppColors.bgSubtle,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.sarabun(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// Keep HeroPill for backward compat (used elsewhere)
class HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const HeroPill({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _StatChip(icon: icon, label: label, isDark: isDark);
  }
}
