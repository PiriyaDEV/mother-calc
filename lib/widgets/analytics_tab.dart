import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import 'member_avatar.dart';

// ── Color constants ───────────────────────────────────────────
const _kStatBlueFrom   = Color(0xFFEFF6FF); // blue-50
const _kStatBlueTo     = Color(0xFFEEF2FF); // indigo-50
const _kStatBlueBorder = Color(0xFFBFDBFE); // blue-100
const _kStatPurpleFrom = Color(0xFFFAF5FF); // purple-50
const _kStatPurpleTo   = Color(0xFFF5F3FF); // violet-50
const _kStatPurpleBorder = Color(0xFFE9D5FF); // purple-100
const _kStatGreenFrom  = Color(0xFFECFDF5); // emerald-50
const _kStatGreenTo    = Color(0xFFF0FDFA); // teal-50
const _kStatGreenBorder = Color(0xFFA7F3D0); // emerald-100

const _kAmber50   = Color(0xFFFFFBEB);
const _kOrange50  = Color(0xFFFFF7ED);
const _kAmberBorder = Color(0xFFFDE68A); // amber-100
const _kAmber500  = Color(0xFFF59E0B);
const _kAmber600  = Color(0xFFD97706);

const _kBlue400 = Color(0xFF4366f4);
const _kBlue500 = Color(0xFF6b8aff);
const _kEmerald500 = Color(0xFF10B981);

class AnalyticsTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = billProvider.members;
    final items = billProvider.items;

    // Empty state
    if (items.isEmpty || members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'เพิ่มสมาชิกและรายการก่อน',
              style: GoogleFonts.notoSansThai(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Analytics จะแสดงเมื่อมีข้อมูล',
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    // Computed data
    final avgPerPerson =
        members.isNotEmpty ? calc.total / members.length : 0.0;

    // Member totals sorted desc
    final memberTotals = calc.memberSummaries
        .map((s) => _MemberTotal(
              member: s.member,
              total: s.total,
              itemCount: s.items.length,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final biggestPayer = memberTotals.isNotEmpty ? memberTotals.first : null;
    final smallestPayer = memberTotals.isNotEmpty ? memberTotals.last : null;
    final maxMemberTotal =
        memberTotals.isNotEmpty ? memberTotals.first.total : 1.0;

    // Top items sorted desc
    final topItems = (List<BillItem>.from(items)
          ..sort((a, b) => b.price.compareTo(a.price)))
        .take(5)
        .toList();
    final maxItemPrice = topItems.isNotEmpty ? topItems.first.price : 1.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 1. Stats Row ───────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '🧾',
                value: items.length.toString(),
                sub: 'รายการ',
                label: 'รายการทั้งหมด',
                fromColor: _kStatBlueFrom,
                toColor: _kStatBlueTo,
                borderColor: _kStatBlueBorder,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                emoji: '👥',
                value: members.length.toString(),
                sub: 'คน',
                label: 'สมาชิก',
                fromColor: _kStatPurpleFrom,
                toColor: _kStatPurpleTo,
                borderColor: _kStatPurpleBorder,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                emoji: getTotalEmoji(avgPerPerson),
                value: formatNumber(avgPerPerson, decimals: 0),
                sub: 'บาท',
                label: 'เฉลี่ย/คน',
                fromColor: _kStatGreenFrom,
                toColor: _kStatGreenTo,
                borderColor: _kStatGreenBorder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 2. Biggest Spender ─────────────────────────────────
        if (biggestPayer != null) ...[
          _BiggestSpenderCard(
            payer: biggestPayer,
            total: calc.total,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
        ],

        // ── 3. Member Spending Bar Chart ───────────────────────
        _SectionCard(
          isDark: isDark,
          title: '💸 ค่าใช้จ่ายแต่ละคน',
          child: Column(
            children: memberTotals.asMap().entries.map((entry) {
              final rank = entry.key;
              final mt = entry.value;
              final pct = maxMemberTotal > 0
                  ? (mt.total / maxMemberTotal)
                  : 0.0;
              final billPct = calc.total > 0
                  ? (mt.total / calc.total * 100).round()
                  : 0;
              final color = colorFromHex(mt.member.color);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Rank indicator
                        SizedBox(
                          width: 28,
                          child: rank == 0
                              ? const Text('🥇',
                                  style: TextStyle(fontSize: 16))
                              : rank == 1
                                  ? const Text('🥈',
                                      style: TextStyle(fontSize: 16))
                                  : rank == 2
                                      ? const Text('🥉',
                                          style: TextStyle(fontSize: 16))
                                      : MemberAvatar(
                                          name: mt.member.name,
                                          color: color,
                                          size: 16,
                                        ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            mt.member.name,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${formatNumber(mt.total)} บาท ($billPct%)',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 34),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          backgroundColor: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
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

        // ── 4. Top Items Bar Chart ─────────────────────────────
        _SectionCard(
          isDark: isDark,
          title: '🔥 รายการแพงสุด',
          child: Column(
            children: topItems.asMap().entries.map((entry) {
              final rank = entry.key;
              final item = entry.value;
              final pct = maxItemPrice > 0
                  ? (item.price / maxItemPrice)
                  : 0.0;
              final sharedCount = item.shares.keys.length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Rank indicator
                        SizedBox(
                          width: 28,
                          child: rank == 0
                              ? const Text('🥇',
                                  style: TextStyle(fontSize: 16))
                              : rank == 1
                                  ? const Text('🥈',
                                      style: TextStyle(fontSize: 16))
                                  : rank == 2
                                      ? const Text('🥉',
                                          style: TextStyle(fontSize: 16))
                                      : Text(
                                          '${rank + 1}.',
                                          style: GoogleFonts.notoSansThai(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.textTertiaryDark
                                                : AppColors.textTertiaryLight,
                                          ),
                                        ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          '${formatNumber(item.price)} บาท ($sharedCount คน)',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kBlue400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 34),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 6,
                          child: LayoutBuilder(
                            builder: (ctx, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                    width: constraints.maxWidth,
                                    color: isDark
                                        ? const Color(0xFF374151)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                  Container(
                                    width: constraints.maxWidth *
                                        pct.clamp(0.0, 1.0),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_kBlue400, _kBlue500],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
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

        // ── 5. Fairness Section ────────────────────────────────
        if (memberTotals.length >= 2 &&
            biggestPayer != null &&
            smallestPayer != null) ...[
          _FairnessCard(
            biggestPayer: biggestPayer,
            smallestPayer: smallestPayer,
            avgPerPerson: avgPerPerson,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
        ],

        // ── 6. Items Per Member Grid ───────────────────────────
        _SectionCard(
          isDark: isDark,
          title: '📋 รายการต่อคน',
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3.0,
            ),
            itemCount: memberTotals.length,
            itemBuilder: (ctx, i) {
              final mt = memberTotals[i];
              final color = colorFromHex(mt.member.color);
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    MemberAvatar(
                        name: mt.member.name, color: color, size: 24),
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
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${mt.itemCount} รายการ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : const Color(0xFF9CA3AF),
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
}

// ── Stat Card ─────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String sub;
  final String label;
  final Color fromColor;
  final Color toColor;
  final Color borderColor;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.sub,
    required this.label,
    required this.fromColor,
    required this.toColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [fromColor, toColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.notoSansThai(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827), // gray-900
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.notoSansThai(
              fontSize: 10,
              color: const Color(0xFF6B7280), // gray-500
            ),
          ),
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 10,
              color: const Color(0xFF9CA3AF), // gray-400
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

  const _BiggestSpenderCard({
    required this.payer,
    required this.total,
    required this.isDark,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 จ่ายเยอะสุด',
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kAmber600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              MemberAvatar(name: payer.member.name, color: color, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payer.member.name,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '${payer.itemCount} รายการ',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
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
                  Text(
                    '$pct% ของบิล',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
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
    final ratio = biggestPayer.total /
        (smallestPayer.total > 0 ? smallestPayer.total : 1);
    final String fairnessEmoji;
    if (ratio > 3.0) {
      fairnessEmoji = '😬';
    } else if (ratio > 1.5) {
      fairnessEmoji = '🤔';
    } else {
      fairnessEmoji = '😊';
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
          Text(
            '⚖️ ความเท่าเทียม',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 12),
          Row(
            children: [
              // Smallest payer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'จ่ายน้อยสุด',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      smallestPayer.member.name,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${formatNumber(smallestPayer.total)} บาท',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kEmerald500,
                      ),
                    ),
                  ],
                ),
              ),
              // Center emoji + ratio
              Column(
                children: [
                  Text(fairnessEmoji,
                      style: const TextStyle(fontSize: 28)),
                  Text(
                    ratioText,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              // Biggest payer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'จ่ายเยอะสุด',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      biggestPayer.member.name,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${formatNumber(biggestPayer.total)} บาท',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kAmber500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 10),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Card wrapper ──────────────────────────────────────
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
          Text(
            title,
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
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

  const _MemberTotal({
    required this.member,
    required this.total,
    required this.itemCount,
  });
}
