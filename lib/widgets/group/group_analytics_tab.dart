import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
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
  late List<_MemberSpend> _memberSpends;
  late List<Bill> _billsByDate;
  late Map<String, int> _statusCounts;

  static const _chartColors = [
    AppColors.primaryBlue,
    AppColors.accent,
    AppColors.emerald,
    AppColors.amber,
    AppColors.red,
    AppColors.violet,
    AppColors.accentAqua,
    Color(0xFFEC4899),
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

    // Unique members across all bills (by id)
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

    // ── Member spending across all bills ──────────────────────────
    // Aggregate each unique member's total spend across all bills
    final memberSpendMap = <String, _MemberSpend>{};
    for (final bill in widget.bills) {
      final calc = calculateBill(bill);
      for (final summary in calc.memberSummaries) {
        final key = summary.member.id;
        if (memberSpendMap.containsKey(key)) {
          memberSpendMap[key] = _MemberSpend(
            name: summary.member.name,
            color: summary.member.color,
            total: memberSpendMap[key]!.total + summary.total,
            billCount: memberSpendMap[key]!.billCount + 1,
          );
        } else {
          memberSpendMap[key] = _MemberSpend(
            name: summary.member.name,
            color: summary.member.color,
            total: summary.total,
            billCount: 1,
          );
        }
      }
    }
    _memberSpends = memberSpendMap.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    // ── Bills sorted by date for trend chart ─────────────────────
    _billsByDate = List<Bill>.from(widget.bills)
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return aDate.compareTo(bDate);
      });

    // ── Status counts ─────────────────────────────────────────────
    _statusCounts = {
      'draft': 0,
      'pending_payment': 0,
      'completed': 0,
    };
    for (final bill in widget.bills) {
      _statusCounts[bill.status] = (_statusCounts[bill.status] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    if (_allItems.isEmpty) {
      return Center(
        child: GroupDetailEmptyState(
          icon: Icons.analytics_outlined,
          label: l.t('analytics_no_data_group'),
          sub: l.t('analytics_add_bill_first'),
          isDark: widget.isDark,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Hero stats ─────────────────────────────────────────────
        _buildHeroStats(
            _totalAmount, _allItems.length, _avgPerBill, _totalMembers),
        const SizedBox(height: AppSpacing.lg),

        // ── Pie chart per bill ─────────────────────────────────────
        if (widget.bills.length > 1) ...[
          TouchablePieChart(
            sortedBills: _sortedBills,
            totalAmount: _totalAmount,
            chartColors: _chartColors,
            isDark: widget.isDark,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Bill comparison bar chart ──────────────────────────────
        if (widget.bills.length >= 2) ...[
          _buildBillsBarChart(_sortedBills),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Member spending bar chart ──────────────────────────────
        if (_memberSpends.isNotEmpty) ...[
          _buildMemberSpendingCard(_memberSpends),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Spending trend line chart ──────────────────────────────
        if (_billsByDate.length >= 2) ...[
          _buildSpendingTrendCard(_billsByDate),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Bill status donut ──────────────────────────────────────
        if (widget.bills.length >= 2) ...[
          _buildStatusDonutCard(_statusCounts),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Top items ─────────────────────────────────────────────
        _buildTopItemsCard(_topItems),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  // ── Hero stats card ────────────────────────────────────────────────────────
  Widget _buildHeroStats(
      double total, int itemCount, double avgPerBill, int memberCount) {
    final l = context.read<LocaleProvider>();
    final isDark = widget.isDark;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: const [AppShadows.card],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.t('analytics_group_total'),
                style: GoogleFonts.sarabun(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatNumber(total)} บาท',
                style: GoogleFonts.sarabun(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _HeroStatPill(
                      label: l.t('unit_bills').replaceFirst('{count}', '${widget.bills.length}'),
                      icon: Icons.receipt_rounded),
                  const SizedBox(width: 8),
                  _HeroStatPill(
                      label: l.t('unit_items').replaceFirst('{count}', '$itemCount'),
                      icon: Icons.list_rounded),
                  const SizedBox(width: 8),
                  _HeroStatPill(
                      label: l.t('unit_people').replaceFirst('{count}', '$memberCount'),
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
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
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
                      AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Center(
                    child: Text('📊',
                        style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l.t('analytics_avg_per_bill'),
                  style: GoogleFonts.sarabun(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              Text(
                '${formatNumber(avgPerBill)} บาท',
                style: GoogleFonts.sarabun(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bill comparison bar chart ──────────────────────────────────────────────
  Widget _buildBillsBarChart(List<Bill> sortedBills) {
    final l = context.read<LocaleProvider>();
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

    return _SectionCard(
      isDark: isDark,
      title: l.t('analytics_compare_bills'),
      child: SizedBox(
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
                    '${bill.emoji ?? '🧾'} ${bill.title}\n${formatNumber(rod.toY)} บาท',
                    GoogleFonts.sarabun(
                      color: AppColors.surface,
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
                      style: GoogleFonts.sarabun(
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
              horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }

  // ── Member spending horizontal bar chart ───────────────────────────────────
  Widget _buildMemberSpendingCard(List<_MemberSpend> memberSpends) {
    final l = context.read<LocaleProvider>();
    final isDark = widget.isDark;
    final display = memberSpends.take(8).toList();
    final maxSpend = display.isNotEmpty ? display.first.total : 1.0;

    return _SectionCard(
      isDark: isDark,
      title: l.t('analytics_member_spending'),
      child: Column(
        children: display.asMap().entries.map((entry) {
          final rank = entry.key;
          final ms = entry.value;
          final pct = maxSpend > 0 ? ms.total / maxSpend : 0.0;
          final totalPct = _totalAmount > 0
              ? (ms.total / _totalAmount * 100).round()
              : 0;
          final color = colorFromHex(ms.color);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: rank == 0
                          ? const Text('🥇', style: TextStyle(fontSize: 15))
                          : rank == 1
                              ? const Text('🥈', style: TextStyle(fontSize: 15))
                              : rank == 2
                                  ? const Text('🥉', style: TextStyle(fontSize: 15))
                                  : Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${rank + 1}',
                                          style: GoogleFonts.sarabun(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ms.name,
                        style: GoogleFonts.sarabun(
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
                      '${formatNumber(ms.total)} บาท',
                      style: GoogleFonts.sarabun(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: Text(
                        '$totalPct%',
                        style: GoogleFonts.sarabun(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.neutral100,
                        ),
                        FractionallySizedBox(
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.xs),
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
        }).toList(),
      ),
    );
  }

  // ── Spending trend line chart ──────────────────────────────────────────────
  Widget _buildSpendingTrendCard(List<Bill> billsByDate) {
    final l = context.read<LocaleProvider>();
    final isDark = widget.isDark;
    final display = billsByDate.take(10).toList();

    // Build cumulative or per-bill spots
    final spots = display.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.total);
    }).toList();

    final maxY = display.fold<double>(
        0, (m, b) => b.total > m ? b.total : m);

    return _SectionCard(
      isDark: isDark,
      title: l.t('analytics_spending_trend'),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (display.length - 1).toDouble(),
            minY: 0,
            maxY: maxY * 1.25,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final bill = display[spot.x.toInt()];
                    return LineTooltipItem(
                      '${bill.emoji ?? '🧾'} ${bill.title}\n${formatNumber(spot.y)} บาท',
                      GoogleFonts.sarabun(
                        color: AppColors.surface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= display.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        display[i].emoji ?? '🧾',
                        style: const TextStyle(fontSize: 12),
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
                      style: GoogleFonts.sarabun(
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
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: AppColors.primaryBlue,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primaryBlue,
                    strokeWidth: 2,
                    strokeColor: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withValues(alpha: 0.18),
                      AppColors.primaryBlue.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bill status donut chart ────────────────────────────────────────────────
  Widget _buildStatusDonutCard(Map<String, int> statusCounts) {
    final l = context.read<LocaleProvider>();
    final isDark = widget.isDark;

    final statusConfig = [
      _StatusConfig(
        key: 'draft',
        label: l.t('bill_status_draft'),
        color: AppColors.amber,
        icon: Icons.edit_outlined,
      ),
      _StatusConfig(
        key: 'pending_payment',
        label: l.t('bill_status_pending'),
        color: AppColors.accent,
        icon: Icons.hourglass_empty_rounded,
      ),
      _StatusConfig(
        key: 'completed',
        label: l.t('bill_status_completed'),
        color: AppColors.emerald,
        icon: Icons.check_circle_outline_rounded,
      ),
    ];

    final total = statusCounts.values.fold<int>(0, (s, v) => s + v);
    if (total == 0) return const SizedBox.shrink();

    final sections = statusConfig
        .where((s) => (statusCounts[s.key] ?? 0) > 0)
        .map((s) {
      final count = statusCounts[s.key] ?? 0;
      final pct = total > 0 ? count / total * 100 : 0.0;
      return PieChartSectionData(
        color: s.color,
        value: count.toDouble(),
        title: pct >= 15 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 44,
        titleStyle: GoogleFonts.sarabun(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();

    return _SectionCard(
      isDark: isDark,
      title: l.t('analytics_bill_status'),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 28,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: statusConfig.map((s) {
                final count = statusCounts[s.key] ?? 0;
                final pct = total > 0
                    ? (count / total * 100).toStringAsFixed(0)
                    : '0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(AppRadii.xs),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          style: GoogleFonts.sarabun(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      Text(
                        '$count',
                        style: GoogleFonts.sarabun(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: s.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($pct%)',
                        style: GoogleFonts.sarabun(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top items card ─────────────────────────────────────────────────────────
  Widget _buildTopItemsCard(List<BillItem> topItems) {
    final l = context.read<LocaleProvider>();
    final isDark = widget.isDark;
    final maxPrice = topItems.isNotEmpty ? topItems.first.price : 1.0;
    return _SectionCard(
      isDark: isDark,
      title: l.t('analytics_top_items'),
      child: Column(
        children: topItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final pct = maxPrice > 0 ? item.price / maxPrice : 0.0;
          const colors = [
            AppColors.primaryBlue,
            AppColors.primaryBlue,
            AppColors.accent,
            AppColors.emerald,
            AppColors.amber,
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
                        style: GoogleFonts.sarabun(
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
                      '${formatNumber(item.price)} บาท',
                      style: GoogleFonts.sarabun(
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
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: Stack(
                      children: [
                        Container(
                            height: 7,
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                        FractionallySizedBox(
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                color,
                                color.withValues(alpha: 0.6)
                              ]),
                              borderRadius: BorderRadius.circular(AppRadii.sm),
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
        }).toList(),
      ),
    );
  }
}

// ── Internal data classes ──────────────────────────────────────────────────

class _MemberSpend {
  final String name;
  final String color;
  final double total;
  final int billCount;

  const _MemberSpend({
    required this.name,
    required this.color,
    required this.total,
    required this.billCount,
  });
}

class _StatusConfig {
  final String key;
  final String label;
  final Color color;
  final IconData icon;

  const _StatusConfig({
    required this.key,
    required this.label,
    required this.color,
    required this.icon,
  });
}

// ── Reusable section card ──────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: GoogleFonts.sarabun(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

// ── Hero stat pill ─────────────────────────────────────────────────────────
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
            style: GoogleFonts.sarabun(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}
