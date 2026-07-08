import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';

/// Owns only [_pieTouchedIndex] so drag-setState is confined to this subtree
/// and does NOT rebuild the whole analytics tab.
class TouchablePieChart extends StatefulWidget {
  final List<Bill> sortedBills;
  final double totalAmount;
  final List<Color> chartColors;
  final bool isDark;

  const TouchablePieChart({
    super.key,
    required this.sortedBills,
    required this.totalAmount,
    required this.chartColors,
    required this.isDark,
  });

  @override
  State<TouchablePieChart> createState() => _TouchablePieChartState();
}

class _TouchablePieChartState extends State<TouchablePieChart> {
  int _pieTouchedIndex = -1;

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = widget.isDark;
    final displayBills = widget.sortedBills.take(8).toList();
    final totalAmount = widget.totalAmount;

    final sections = displayBills.asMap().entries.map((entry) {
      final i = entry.key;
      final bill = entry.value;
      final billTotal =
          bill.items.fold<double>(0, (s, item) => s + item.price);
      final pct = totalAmount > 0 ? billTotal / totalAmount * 100 : 0.0;
      final color = widget.chartColors[i % widget.chartColors.length];
      final isTouched = i == _pieTouchedIndex;

      return PieChartSectionData(
        color: color,
        value: billTotal,
        title: pct >= 10 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: isTouched ? 90 : 75,
        titleStyle: GoogleFonts.sarabun(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.surface,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: isDark ? null : const [AppShadows.subtle],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.t('analytics_pie_chart_per_bill'),
              style: GoogleFonts.sarabun(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: RepaintBoundary(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response?.touchedSection == null) {
                            _pieTouchedIndex = -1;
                            return;
                          }
                          _pieTouchedIndex =
                              response!.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: sections,
                    centerSpaceRadius: 44,
                    sectionsSpace: 2,
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 300),
                  swapAnimationCurve: Curves.easeInOut,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Legend
            ...displayBills.asMap().entries.map((entry) {
              final i = entry.key;
              final bill = entry.value;
              final billTotal =
                  bill.items.fold<double>(0, (s, item) => s + item.price);
              final pct = totalAmount > 0
                  ? (billTotal / totalAmount * 100).toStringAsFixed(1)
                  : '0';
              final color =
                  widget.chartColors[i % widget.chartColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppRadii.xs)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${bill.emoji ?? '🧾'} ${bill.title}',
                        style: GoogleFonts.sarabun(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: GoogleFonts.sarabun(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${formatNumber(billTotal)} บาท',
                      style: GoogleFonts.sarabun(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
