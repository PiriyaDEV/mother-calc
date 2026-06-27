import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/member_avatar.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text(
              'ฉัน',
              style: GoogleFonts.notoSansThai(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 20),

            // Profile card
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    MemberAvatar(
                      name: profile?.displayName ?? profile?.username ?? '?',
                      color: AppColors.primary,
                      size: 52,
                      avatarUrl: profile?.avatarUrl,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.displayName ?? profile?.username ?? 'ผู้ใช้',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          if (profile?.username != null)
                            Text(
                              '@${profile!.username}',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          Text(
                            auth.user?.email ?? '',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Settings section
            _SectionHeader(title: 'การตั้งค่า'),
            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              label: 'โหมดมืด',
              trailing: Switch(
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggle(),
                activeColor: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Account section
            _SectionHeader(title: 'บัญชี'),
            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.person_outline_rounded,
              label: 'แก้ไขโปรไฟล์',
              onTap: () => context.push('/profile'),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'การแจ้งเตือน',
              onTap: () => context.push('/notifications'),
            ),

            const SizedBox(height: 24),

            // Sign out
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('ออกจากระบบ', style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold)),
                    content: Text('คุณต้องการออกจากระบบหรือไม่?', style: GoogleFonts.notoSansThai()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('ยกเลิก', style: GoogleFonts.notoSansThai(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        )),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('ออกจากระบบ', style: GoogleFonts.notoSansThai(
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                        )),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await context.read<AuthProvider>().signOut();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.red.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: AppColors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ออกจากระบบ',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // App version
            Center(
              child: Text(
                'Kidtang v1.0.0',
                style: GoogleFonts.notoSansThai(
                  fontSize: 12,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.notoSansThai(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
          ],
        ),
      ),
    );
  }
}
