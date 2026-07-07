import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'section_card.dart';

class TopItemsCard extends StatelessWidget {
  final List<BillItem> topItems;
  final double maxItemPrice;
  final bool isDark;

  const TopItemsCard({
    super.key,
    required this.topItems,
    required this.maxItemPrice,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      isDark: isDark,
      title: '🔥 รายการแพงสุด',
      child: Column(
        children: topItems.asMap().entries.map((entry) {
          final rank = entry.key;
          final item = entry.value;
          final pct = maxItemPrice > 0 ? item.price / maxItemPrice : 0.0;
          final sharedCount = item.splitWeights.keys.length;

          const barColors = [
            Color(0xFF4366f4),
            Color(0xFF7C3AED),
            Color(0xFFEC4899),
            Color(0xFF10B981),
            Color(0xFFF59E0B),
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
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiaryLight,
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
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$sharedCount คน',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
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
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  barColor,
                                  barColor.withValues(alpha: 0.7)
                                ],
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
