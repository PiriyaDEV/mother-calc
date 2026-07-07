import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'member_total.dart';
import 'section_card.dart';

/// Owns [_pieTouchedIndex] locally so that touch/drag events on the pie chart
/// only rebuild this widget — not the entire AnalyticsTab.
class PieChartCard extends StatefulWidget {
  final List<MemberTotal> memberTotals;
  final double total;
  final bool isDark;

  const PieChartCard({
    super.key,
    required this.memberTotals,
    required this.total,
    required this.isDark,
  });

  @override
  State<PieChartCard> createState() => _PieChartCardState();
}

class _PieChartCardState extends State<PieChartCard> {
  int _pieTouchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.memberTotals.isEmpty || widget.total == 0) {
      return const SizedBox.shrink();
    }

    final sections = widget.memberTotals.asMap().entries.map((entry) {
      final i = entry.key;
      final mt = entry.value;
      final color = colorFromHex(mt.member.color);
      final pct = widget.total > 0 ? mt.total / widget.total * 100 : 0.0;
      final isTouched = i == _pieTouchedIndex;
      return PieChartSectionData(
        color: color,
        value: mt.total,
        title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: isTouched ? 90 : 75,
        titleStyle: GoogleFonts.notoSansThai(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();

    return SectionCard(
      isDark: widget.isDark,
      title: '🥧 สัดส่วนค่าใช้จ่าย',
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: RepaintBoundary(
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _pieTouchedIndex = -1;
                          return;
                        }
                        _pieTouchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: widget.memberTotals.map((mt) {
              final color = colorFromHex(mt.member.color);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    mt.member.name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
