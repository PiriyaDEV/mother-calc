import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import 'member_avatar.dart';

const _kAmber50    = Color(0xFFFFFBEB);
const _kOrange50   = Color(0xFFFFF7ED);
const _kAmberBorder = Color(0xFFFDE68A);
const _kAmber500   = Color(0xFFF59E0B);
const _kAmber600   = Color(0xFFD97706);
const _kEmerald500 = Color(0xFF10B981);

class AnalyticsTab extends StatefulWidget {
  final Bill bill;
  final BillProvider billProvider;
  final BillCalculation calc;

  const AnalyticsTab({
    super.key,
    required this.bill,
    required this.billProvider,
    required this.calc,
  });

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int _pieTouchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = widget.billProvider.members;
    final items = widget.billProvider.items;

    if (items.isEmpty || members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primaryLight.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('📊', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'เพิ่มสมาชิกและรายการก่อน',
              style: GoogleFonts.notoSansThai(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'กราฟและสถิติจะแสดงเมื่อมีข้อมูล',
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      );
    }

    final avgPerPerson = members.isNotEmpty ? widget.calc.total / members.length : 0.0;

    final memberTotals = widget.calc.memberSummaries
        .map((s) => _MemberTotal(
              member: s.member,
              total: s.total,
              itemCount: s.items.length,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final biggestPayer = memberTotals.isNotEmpty ? memberTotals.first : null;
    final smallestPayer = memberTotals.isNotEmpty ? memberTotals.last : null;
    final maxMemberTotal = memberTotals.isNotEmpty ? memberTotals.first.total : 1.0;

    final topItems = (List<BillItem>.from(items)..sort((a, b) => b.price.compareTo(a.price)))
        .take(5)
        .toList();
    final maxItemPrice = topItems.isNotEmpty ? topItems.first.price : 1.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Stats Row ──────────────────────────────────────────
        _buildStatsRow(items, members, avgPerPerson, isDark),
        const SizedBox(height: 16),

        // ── Pie Chart - Member Spending ────────────────────────
        _buildPieChartCard(memberTotals, isDark),
        const SizedBox(height: 12),

        // ── Biggest Spender ────────────────────────────────────
        if (biggestPayer != null) ...[
          _BiggestSpenderCard(payer: biggestPayer, total: widget.calc.total, isDark: isDark),
          const SizedBox(height: 12),
        ],

        // ── Member Spending Bars ───────────────────────────────
        _SectionCard(
          isDark: isDark,
          title: '💸 ค่าใช้จ่ายแต่ละคน',
          child: Column(
            children: memberTotals.asMap().entries.map((entry) {
              final rank = entry.key;
              final mt = entry.value;
              final pct = maxMemberTotal > 0 ? mt.total / maxMemberTotal : 0.0;
              final billPct = widget.calc.total > 0 ? (mt.total / widget.calc.total * 100).round() : 0;
              final color = colorFromHex(mt.member.color);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: rank == 0
                              ? const Text('🥇', style: TextStyle(fontSize: 16))
                              : rank == 1
                                  ? const Text('🥈', style: TextStyle(fontSize: 16))
                                  : rank == 2
                                      ? const Text('🥉', style: TextStyle(fontSize: 16))
                                      : MemberAvatar(
                                          name: mt.member.name,
                                          color: color,
                                          size: 18,
                                          avatarUrl: mt.member.profile?.avatarUrl,
                                        ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mt.member.name,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${formatNumber(mt.total)} บาท',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$billPct%',
                            style: GoogleFonts.notoSansThai(
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
                      padding: const EdgeInsets.only(left: 36),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          children: [
                            Container(
                              height: 8,
                              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                            ),
                            FractionallySizedBox(
                              widthFactor: pct.clamp(0.0, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
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
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ── Top Items Bar Chart ────────────────────────────────
        _buildTopItemsCard(topItems, maxItemPrice, isDark),
        const SizedBox(height: 12),

        // ── Fairness Section ───────────────────────────────────
        if (memberTotals.length >= 2 && biggestPayer != null && smallestPayer != null) ...[
          _FairnessCard(
            biggestPayer: biggestPayer,
            smallestPayer: smallestPayer,
            avgPerPerson: avgPerPerson,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
        ],

        // ── Items Per Member ───────────────────────────────────
        _SectionCard(
          isDark: isDark,
          title: '📋 รายการต่อคน',
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3.2,
            ),
            itemCount: memberTotals.length,
            itemBuilder: (ctx, i) {
              final mt = memberTotals[i];
              final color = colorFromHex(mt.member.color);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    MemberAvatar(
                      name: mt.member.name,
                      color: color,
                      size: 26,
                      avatarUrl: mt.member.profile?.avatarUrl,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mt.member.name,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${mt.itemCount} รายการ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 10,
                              color: isDark ? AppColors.textTertiaryDark : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatsRow(List<BillItem> items, List<BillMember> members, double avgPerPerson, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _GradientStatCard(
            emoji: '🧾',
            value: items.length.toString(),
            label: 'รายการ',
            gradientColors: const [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
            borderColor: const Color(0xFFBFDBFE),
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GradientStatCard(
            emoji: '👥',
            value: members.length.toString(),
            label: 'สมาชิก',
            gradientColors: const [Color(0xFFFAF5FF), Color(0xFFF5F3FF)],
            borderColor: const Color(0xFFE9D5FF),
            valueColor: const Color(0xFFA855F7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GradientStatCard(
            emoji: '💰',
            value: formatNumber(avgPerPerson, decimals: 0),
            label: 'เฉลี่ย/คน',
            gradientColors: const [Color(0xFFECFDF5), Color(0xFFF0FDFA)],
            borderColor: const Color(0xFFA7F3D0),
            valueColor: _kEmerald500,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartCard(List<_MemberTotal> memberTotals, bool isDark) {
    if (memberTotals.isEmpty || widget.calc.total == 0) return const SizedBox.shrink();

    final sections = memberTotals.asMap().entries.map((entry) {
      final i = entry.key;
      final mt = entry.value;
      final color = colorFromHex(mt.member.color);
      final pct = widget.calc.total > 0 ? mt.total / widget.calc.total * 100 : 0.0;
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

    return _SectionCard(
      isDark: isDark,
      title: '🥧 สัดส่วนค่าใช้จ่าย',
      child: Column(
        children: [
          SizedBox(
            height: 200,
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
                      _pieTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: memberTotals.map((mt) {
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
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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

  Widget _buildTopItemsCard(List<BillItem> topItems, double maxItemPrice, bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: '🔥 รายการแพงสุด',
      child: Column(
        children: topItems.asMap().entries.map((entry) {
          final rank = entry.key;
          final item = entry.value;
          final pct = maxItemPrice > 0 ? item.price / maxItemPrice : 0.0;
          final sharedCount = item.shares.keys.length;

          final barColors = [
            const Color(0xFF4366f4),
            const Color(0xFF7C3AED),
            const Color(0xFFEC4899),
            const Color(0xFF10B981),
            const Color(0xFFF59E0B),
          ];
          final barColor = barColors[rank % barColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: rank == 0
                          ? const Text('🥇', style: TextStyle(fontSize: 16))
                          : rank == 1
                              ? const Text('🥈', style: TextStyle(fontSize: 16))
                              : rank == 2
                                  ? const Text('🥉', style: TextStyle(fontSize: 16))
                                  : Text(
                                      '${rank + 1}.',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                                      ),
                                    ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      '${formatNumber(item.price)} บาท',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$sharedCount คน',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 10,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [barColor, barColor.withValues(alpha: 0.7)],
                              ),
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
        }).toList(),
      ),
    );
  }
}

// ── Gradient Stat Card ────────────────────────────────────────
class _GradientStatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color valueColor;

  const _GradientStatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.gradientColors,
    required this.borderColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.notoSansThai(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Biggest Spender Card ──────────────────────────────────────
class _BiggestSpenderCard extends StatelessWidget {
  final _MemberTotal payer;
  final double total;
  final bool isDark;

  const _BiggestSpenderCard({required this.payer, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(payer.member.color);
    final pct = total > 0 ? (payer.total / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kAmber50, _kOrange50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAmberBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kAmber500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
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
                  'จ่ายเยอะสุด',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kAmber600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    MemberAvatar(name: payer.member.name, color: color, size: 20, avatarUrl: payer.member.profile?.avatarUrl),
                    const SizedBox(width: 6),
                    Text(
                      payer.member.name,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${payer.itemCount} รายการ',
                  style: GoogleFonts.notoSansThai(fontSize: 11, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatNumber(payer.total)} บาท',
                style: GoogleFonts.notoSansThai(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kAmber600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kAmber500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pct% ของบิล',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kAmber600,
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

// ── Fairness Card ─────────────────────────────────────────────
class _FairnessCard extends StatelessWidget {
  final _MemberTotal biggestPayer;
  final _MemberTotal smallestPayer;
  final double avgPerPerson;
  final bool isDark;

  const _FairnessCard({
    required this.biggestPayer,
    required this.smallestPayer,
    required this.avgPerPerson,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = biggestPayer.total / (smallestPayer.total > 0 ? smallestPayer.total : 1);
    final String fairnessEmoji;
    final Color fairnessColor;
    if (ratio > 3.0) {
      fairnessEmoji = '😬';
      fairnessColor = AppColors.red;
    } else if (ratio > 1.5) {
      fairnessEmoji = '🤔';
      fairnessColor = _kAmber500;
    } else {
      fairnessEmoji = '😊';
      fairnessColor = _kEmerald500;
    }
    final ratioText = '${ratio.toStringAsFixed(1)}x';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
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
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: fairnessColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fairnessEmoji, style: const TextStyle(fontSize: 14)),
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
          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FairnessPersonCol(
                  label: 'จ่ายน้อยสุด',
                  name: smallestPayer.member.name,
                  amount: smallestPayer.total,
                  color: _kEmerald500,
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
                child: _FairnessPersonCol(
                  label: 'จ่ายเยอะสุด',
                  name: biggestPayer.member.name,
                  amount: biggestPayer.total,
                  color: _kAmber500,
                  isDark: isDark,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เฉลี่ยต่อคน',
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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

class _FairnessPersonCol extends StatelessWidget {
  final String label;
  final String name;
  final double amount;
  final Color color;
  final bool isDark;
  final CrossAxisAlignment align;

  const _FairnessPersonCol({
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
              color: isDark ? AppColors.textTertiaryDark : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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

// ── Section Card ──────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const _SectionCard({required this.isDark, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────
class _MemberTotal {
  final BillMember member;
  final double total;
  final int itemCount;

  const _MemberTotal({required this.member, required this.total, required this.itemCount});
}
