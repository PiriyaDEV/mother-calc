import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class GroupTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;
  final int acceptedCount;
  final int billsCount;

  const GroupTabBar({
    super.key,
    required this.controller,
    required this.isDark,
    required this.acceptedCount,
    required this.billsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: isDark ? AppColors.borderDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelColor: AppColors.primary,
        unselectedLabelColor:
            isDark ? AppColors.textTertiaryDark : AppColors.neutral600,
        labelStyle: GoogleFonts.notoSansThai(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansThai(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        tabs: [
          _CountTab(label: context.watch<LocaleProvider>().t('group_tab_members'), count: acceptedCount, isDark: isDark),
          _CountTab(label: context.watch<LocaleProvider>().t('group_tab_bills'), count: billsCount, isDark: isDark),
          Tab(text: context.watch<LocaleProvider>().t('group_tab_summary')),
          Tab(text: context.watch<LocaleProvider>().t('group_tab_analytics')),
        ],
      ),
    );
  }
}

class _CountTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isDark;

  const _CountTab({
    required this.label,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.notoSansThai(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
