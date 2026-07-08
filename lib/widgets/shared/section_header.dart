import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String label;
  final int? trailingCount;
  final Widget? trailingWidget;

  const SectionHeaderWidget({
    super.key,
    required this.label,
    this.trailingCount,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.sarabun(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          ),
        ),
        if (trailingCount != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Text(
              '$trailingCount',
              style: GoogleFonts.sarabun(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (trailingWidget != null) trailingWidget!,
      ],
    );
  }
}
