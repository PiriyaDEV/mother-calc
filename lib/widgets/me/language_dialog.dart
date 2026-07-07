import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class LanguageDialog extends StatelessWidget {
  final String currentLocale;
  final ValueChanged<String> onSelect;

  const LanguageDialog({
    super.key,
    required this.currentLocale,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.t('me_language_select'),
              style: GoogleFonts.notoSansThai(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            LangOption(
              flag: '🇹🇭',
              name: 'ภาษาไทย',
              subtitle: 'Thai',
              selected: currentLocale == 'th',
              isDark: isDark,
              onTap: () => onSelect('th'),
            ),
            const SizedBox(height: 8),
            LangOption(
              flag: '🇬🇧',
              name: 'English',
              subtitle: l.t('language_english'),
              selected: currentLocale == 'en',
              isDark: isDark,
              onTap: () => onSelect('en'),
            ),
          ],
        ),
      ),
    );
  }
}

class LangOption extends StatelessWidget {
  final String flag;
  final String name;
  final String subtitle;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const LangOption({
    super.key,
    required this.flag,
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.bgDark : AppColors.bgLight),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
