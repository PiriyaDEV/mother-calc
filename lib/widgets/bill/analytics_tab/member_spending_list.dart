import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';
import 'member_total.dart';
import 'section_card.dart';

class MemberSpendingList extends StatelessWidget {
  final List<MemberTotal> memberTotals;
  final double billTotal;
  final bool isDark;

  const MemberSpendingList({
    super.key,
    required this.memberTotals,
    required this.billTotal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final maxMemberTotal =
        memberTotals.isNotEmpty ? memberTotals.first.total : 1.0;

    return SectionCard(
      isDark: isDark,
      title: l.t('analytics_member_spending'),
      child: Column(
        children: memberTotals.asMap().entries.map((entry) {
          final rank = entry.key;
          final mt = entry.value;
          final pct =
              maxMemberTotal > 0 ? mt.total / maxMemberTotal : 0.0;
          final billPct = billTotal > 0
              ? (mt.total / billTotal * 100).round()
              : 0;
          final color = colorFromHex(mt.member.color);
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                                        size: 18,
                                        avatarUrl:
                                            mt.member.profile?.avatarUrl,
                                      ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mt.member.name,
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
                        '${formatNumber(mt.total)} บาท',
                        style: GoogleFonts.notoSansThai(
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
            ),
          );
        }).toList(),
      ),
    );
  }
}
