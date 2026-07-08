import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/section_header.dart';
import 'settings_tile.dart';

class SettingsSection extends StatelessWidget {
  final bool isDark;
  final bool isThai;
  final VoidCallback onToggleDark;
  final VoidCallback onLanguageTap;

  const SettingsSection({
    super.key,
    required this.isDark,
    required this.isThai,
    required this.onToggleDark,
    required this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(label: l.t('me_settings')),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              // Dark mode toggle
              SettingsTile(
                isDark: isDark,
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                iconColor: isDark
                    ? const Color(0xFF7C83FD)
                    : const Color(0xFFFFB23E),
                label: l.t('me_dark_mode'),
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => onToggleDark(),
                  activeColor: AppColors.primary,
                  activeTrackColor: AppColors.primaryFaint,
                  inactiveThumbColor: AppColors.neutral400,
                  inactiveTrackColor: AppColors.neutral100,
                ),
                onTap: onToggleDark,
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
              // Language
              SettingsTile(
                isDark: isDark,
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF34C77B),
                label: l.t('language'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    isThai ? l.t('me_language_thai') : 'EN',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                onTap: onLanguageTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
