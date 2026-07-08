import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class PillTabBar extends StatelessWidget {
  final TabController controller;
  final List<CountTab> tabs;

  const PillTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: isDark ? AppColors.borderDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: const [AppShadows.subtle],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.primary,
        unselectedLabelColor:
            isDark ? AppColors.textTertiaryDark : AppColors.neutral600,
        labelStyle:
            GoogleFonts.sarabun(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.sarabun(fontSize: 12),
        tabs: tabs.map((t) => Tab(child: _TabLabel(label: t.label, count: t.count))).toList(),
      ),
    );
  }
}

/// Data class used to describe a tab in [PillTabBar].
/// Pass [count] = 0 to hide the badge.
class CountTab {
  final String label;
  final int count;

  const CountTab({required this.label, required this.count});
}

/// Internal widget that renders the tab label + optional count badge.
class _TabLabel extends StatelessWidget {
  final String label;
  final int count;

  const _TabLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.sarabun(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
