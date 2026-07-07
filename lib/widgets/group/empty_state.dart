import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

/// Screen-owned empty state for group detail tabs.
/// Named [GroupDetailEmptyState] to avoid collision with the shared
/// [EmptyStateWidget] in lib/widgets/empty_state.dart.
class GroupDetailEmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final bool isDark;

  const GroupDetailEmptyState({
    super.key,
    required this.icon,
    required this.label,
    this.sub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          label,
          style: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(
            sub!,
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ],
    );
  }
}
