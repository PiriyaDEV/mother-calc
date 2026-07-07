import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/section_header.dart';
import 'settings_tile.dart';

class SettingsSection extends StatelessWidget {
  final bool isDark;
  final bool isThai;
  final int notifUnread;
  final VoidCallback onToggleDark;
  final VoidCallback onLanguageTap;
  final VoidCallback onNotificationsTap;

  const SettingsSection({
    super.key,
    required this.isDark,
    required this.isThai,
    required this.notifUnread,
    required this.onToggleDark,
    required this.onLanguageTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderWidget(label: 'การตั้งค่า'),
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
                label: 'โหมดสีเข้ม',
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
                label: 'ภาษา',
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
                    isThai ? '🇹🇭 ไทย' : '🇬🇧 EN',
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
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
              // Notifications
              SettingsTile(
                isDark: isDark,
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFFFF5C5C),
                label: 'การแจ้งเตือน',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (notifUnread > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          notifUnread > 99 ? '99+' : '$notifUnread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ],
                ),
                onTap: onNotificationsTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
