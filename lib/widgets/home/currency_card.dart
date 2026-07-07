import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class CurrencyCard extends StatelessWidget {
  final String code;
  final String name;
  final String flag;
  final String rateStr;
  final bool isDark;

  const CurrencyCard({
    super.key,
    required this.code,
    required this.name,
    required this.flag,
    required this.rateStr,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.neutral100,
        ),
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -6,
            bottom: -10,
            child: Opacity(
              opacity: 0.18,
              child: Text(flag, style: const TextStyle(fontSize: 52)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  code,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '฿$rateStr',
                style: GoogleFonts.anuphan(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.neutral900Dark
                      : AppColors.neutral900,
                ),
              ),
              Text(
                name,
                style: GoogleFonts.notoSansThai(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.neutral400Dark
                      : AppColors.neutral400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
