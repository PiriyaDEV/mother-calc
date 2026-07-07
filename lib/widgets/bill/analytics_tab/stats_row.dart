import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';

class StatsRow extends StatelessWidget {
  final int itemCount;
  final int memberCount;
  final double avgPerPerson;

  const StatsRow({
    super.key,
    required this.itemCount,
    required this.memberCount,
    required this.avgPerPerson,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientStatCard(
            emoji: '🧾',
            value: itemCount.toString(),
            label: 'รายการ',
            gradientColors: const [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
            borderColor: const Color(0xFFBFDBFE),
            valueColor: const Color(0xFF4366f4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GradientStatCard(
            emoji: '👥',
            value: memberCount.toString(),
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
            valueColor: AppColors.emerald500,
          ),
        ),
      ],
    );
  }
}

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
