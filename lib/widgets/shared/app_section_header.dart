import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

/// A consistent section header used across all screens.
///
/// Flik principle: every content section has a clear visual anchor —
/// a bold title on the left and an optional "see all" action on the right.
/// This eliminates the 4+ inline copies of this pattern scattered across screens.
///
/// Usage:
/// ```dart
/// AppSectionHeader(
///   title: 'Recent Bills',
///   onSeeAll: () => context.go('/bills'),
///   seeAllLabel: 'ดูทั้งหมด',
/// )
/// ```
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel = 'ดูทั้งหมด',
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xxl,
      AppSpacing.lg,
      AppSpacing.md,
    ),
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final primaryColor =
        isDark ? AppColors.primaryBlueDark : AppColors.primaryBlue;
    final chipBg = isDark ? AppColors.accentIceDark : AppColors.accentIce;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.anuphan(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
              ),
            ),
          ),
          if (onSeeAll != null) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  seeAllLabel,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
