import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';
import 'member_total.dart';

const _kAmber50 = Color(0xFFFFFBEB);
const _kOrange50 = Color(0xFFFFF7ED);
const _kAmberBorder = Color(0xFFFDE68A);
const _kAmber500 = Color(0xFFF59E0B);
const _kAmber600 = Color(0xFFD97706);

class BiggestSpenderCard extends StatelessWidget {
  final MemberTotal payer;
  final double total;

  const BiggestSpenderCard({
    super.key,
    required this.payer,
    required this.total,
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
                    MemberAvatar(
                      name: payer.member.name,
                      color: color,
                      size: 20,
                      avatarUrl: payer.member.profile?.avatarUrl,
                    ),
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
                  style: GoogleFonts.notoSansThai(
                      fontSize: 11, color: const Color(0xFF6B7280)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
