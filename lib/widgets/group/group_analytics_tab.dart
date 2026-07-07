import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'empty_state.dart';
import 'touchable_pie_chart.dart';

class GroupAnalyticsTab extends StatefulWidget {
  final List<Bill> bills;
  final bool isDark;

  const GroupAnalyticsTab({
    super.key,
    required this.bills,
    required this.isDark,
  });

  @override
  State<GroupAnalyticsTab> createState() => _GroupAnalyticsTabState();
}

class _GroupAnalyticsTabState extends State<GroupAnalyticsTab> {
  // ── Cached derived data — recomputed only when bills content changes ──
  late List<BillItem> _allItems;
  late double _totalAmount;
  late double _avgPerBill;
  late int _totalMembers;
  late List<Bill> _sortedBills;
  late List<BillItem> _topItems;

  static const _chartColors = [
    Color(0xFF4366f4),
    Color(0xFFA855F7),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
  ];

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void didUpdateWidget(GroupAnalyticsTab old) {
    super.didUpdateWidget(old);
    if (!billsEqual(old.bills, widget.bills)) {
      _recompute();
    }
  }

  void _recompute() {
    _allItems = widget.bills.expand((b) => b.items).toList();
    _totalAmount = widget.bills.fold<double>(0, (s, b) => s + b.total);
    _avgPerBill = widget.bills.isNotEmpty
        ? _totalAmount / widget.bills.length
        : 0.0;
    _totalMembers = widget.bills
        .expand((b) => b.members)
        .map((m) => m.id)
        .toSet()
        .length;
    _sortedBills = List<Bill>.from(widget.bills)
      ..sort((a, b) => b.total.compareTo(a.total));
    _topItems = (List<BillItem>.from(_allItems)
          ..sort((a, b) => b.price.compareTo(a.price)))
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_allItems.isEmpty) {
      return Center(
        child: GroupDetailEmptyState(
          icon: Icons.analytics_outlined,
          label: 'ยังไม่มีข้อมูลวิเคราะห์',
          sub: 'สร้างบิลและเพิ่มรายการก่อน',
          isDark: widget.isDark,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildHeroStats(
            _totalAmount, _allItems.length, _avgPerBill, _totalMembers),
        const SizedBox(height: AppSpacing.lg),

        if (widget.bills.length > 1) ...[
          TouchablePieChart(
            sortedBills: _sortedBills,
            totalAmount: _totalAmount,
            chartColors: _chartColors,
            isDark: widget.isDark,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (widget.bills.length >= 2) ...[
          _buildBillsBarChart(_sortedBills),
          const SizedBox(height: AppSpacing.md),
        ],

        _buildTopItemsCard(_topItems),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildHeroStats(
      double total, int itemCount, double avgPerBill, int memberCount) {
    final isDark = widget.isDark;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4366f4), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4366f4).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ยอดรวมทั้งกลุ่ม',
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '฿${formatNumber(total)}',
                style: GoogleFonts.notoSansThai(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _HeroStatPill(
                      label: '${widget.bills.length} บิล',
                      icon: Icons.receipt_rounded),
                  const SizedBox(width: 8),
                  _HeroStatPill(
                      label: '$itemCount รายการ',
                      icon: Icons.list_rounded),
                  const SizedBox(width: 8),
                  _HeroStatPill(
                      label: '$memberCount คน',
                      icon: Icons.people_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Center(
                    child: Text('📊',
                        style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'เฉลี่ยต่อบิล',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              Text(
                '฿${formatNumber(avgPerBill)}',
                style: GoogleFonts.notoSansThai(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillsBarChart(List<Bill> sortedBills) {
    final isDark = widget.isDark;
    final displayBills = sortedBills.take(6).toList();
    final maxVal = displayBills.fold<double>(
        0, (max, b) => b.total > max ? b.total : max);

    final barGroups = displayBills.asMap().entries.map((entry) {
      final i = entry.key;
      final bill = entry.value;
      final billTotal = bill.total;
      final color = _chartColors[i % _chartColors.length];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: billTotal,
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 28,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 เปรียบเทียบยอดแต่ละบิล',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final bill = displayBills[group.x];
                      return BarTooltipItem(
                        '${bill.emoji ?? '🧾'} ${bill.title}\n฿${formatNumber(rod.toY)}',
                        GoogleFonts.notoSansThai(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= displayBills.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            displayBills[i].emoji ?? '🧾',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          formatNumber(value, decimals: 0),
                          style: GoogleFonts.notoSansThai(
                            fontSize: 9,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
              swapAnimationDuration: const Duration(milliseconds: 400),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsCard(List<BillItem> topItems) {
    final isDark = widget.isDark;
    final maxPrice = topItems.isNotEmpty ? topItems.first.price : 1.0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 รายการแพงสุด',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 14),
          ...topItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final pct = maxPrice > 0 ? item.price / maxPrice : 0.0;
            const colors = [
              Color(0xFF4366f4),
              Color(0xFF7C3AED),
              Color(0xFFEC4899),
              Color(0xFF10B981),
              Color(0xFFF59E0B),
            ];
            final color = colors[idx % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          idx == 0
                              ? '🥇'
                              : idx == 1
                                  ? '🥈'
                                  : idx == 2
                                      ? '🥉'
                                      : '${idx + 1}.',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '฿${formatNumber(item.price)}',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(
                              height: 7,
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5E7EB)),
                          FractionallySizedBox(
                            widthFactor: pct.clamp(0.0, 1.0),
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  color,
                                  color.withValues(alpha: 0.6)
                                ]),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Hero stat pill ─────────────────────────────────────────────
class _HeroStatPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroStatPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
