import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';

class StatsGrid extends StatelessWidget {
  final bool isDark;
  const StatsGrid({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    return Selector<BillsStore, BillAggregateStats?>(
      selector: (_, s) => s.stats,
      builder: (context, stats, _) {
        if (stats == null || stats.totalCount == 0) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final grandTotal = stats.grandTotal;
        final totalItems = stats.totalItems;
        final biggestBillTotal = stats.biggestBillTotal;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
            ),
            delegate: SliverChildListDelegate([
              StatCard(
                icon: Icons.trending_up_rounded,
                label: l.t('stats_avg_per_bill_short'),
                value: '${formatNumber(grandTotal / stats.totalCount)} บาท',
                accentColor: AppColors.primaryBlue,
                bgColor:
                    isDark ? AppColors.accentIceDark : AppColors.accentIce,
              ),
              StatCard(
                icon: Icons.receipt_long_rounded,
                label: l.t('stats_total_bills'),
                value: l.t('unit_bills').replaceFirst('{count}', '${stats.totalCount}'),
                accentColor: AppColors.violet,
                bgColor: isDark
                    ? AppColors.violet.withValues(alpha: 0.15)
                    : AppColors.violetFaint,
              ),
              StatCard(
                icon: Icons.format_list_bulleted_rounded,
                label: l.t('stats_total_items'),
                value: l.t('unit_items').replaceFirst('{count}', '$totalItems'),
                accentColor: AppColors.amber,
                bgColor: isDark
                    ? AppColors.amber.withValues(alpha: 0.12)
                    : AppColors.amberFaint,
              ),
              StatCard(
                icon: Icons.star_rounded,
                label: l.t('stats_biggest_bill'),
                value: '${formatNumber(biggestBillTotal)} บาท',
                accentColor: AppColors.emerald,
                bgColor: isDark
                    ? AppColors.emerald.withValues(alpha: 0.12)
                    : AppColors.greenFaint,
              ),
            ]),
          ),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color bgColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark ? null : const [AppShadows.subtle],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
              Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.sarabun(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.sarabun(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.neutral400Dark
                      : AppColors.neutral400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
