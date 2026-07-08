import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class TagChip extends StatelessWidget {
  final String tag;
  final double fontSize;
  final double borderRadius;

  const TagChip({
    super.key,
    required this.tag,
    this.fontSize = 10,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        '#$tag',
        style: GoogleFonts.sarabun(
          fontSize: fontSize,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
