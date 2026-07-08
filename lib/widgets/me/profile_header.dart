import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'profile_avatar.dart';
import 'toast_banner.dart';
// AppGradients removed — profile header now uses plain background (Clubhouse style)

class ProfileHeader extends StatelessWidget {
  final bool isDark;
  final Profile? profile;
  final bool uploading;
  final VoidCallback onPickAvatar;
  final String? successMessage;
  final String? errorMessage;
  final VoidCallback onDismissError;

  const ProfileHeader({
    super.key,
    required this.isDark,
    required this.profile,
    required this.uploading,
    required this.onPickAvatar,
    required this.onDismissError,
    this.successMessage,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          if (successMessage != null) ...[
            ToastBanner(
                message: successMessage!, isError: false, isDark: isDark),
            const SizedBox(height: 8),
          ],
          if (errorMessage != null) ...[
            ToastBanner(
              message: errorMessage!,
              isError: true,
              isDark: isDark,
              onDismiss: onDismissError,
            ),
            const SizedBox(height: 8),
          ],
          // Clubhouse-style: centered avatar above name
          Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              ProfileAvatar(
                profile: profile,
                size: 80,
                uploading: uploading,
                onPickAvatar: onPickAvatar,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                profile?.displayName ??
                    profile?.username ??
                    context.read<LocaleProvider>().t('notifications_user_fallback'),
                style: GoogleFonts.sarabun(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              if (profile?.username != null) ...[
                const SizedBox(height: 2),
                Text(
                  '@${profile!.username}',
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ],
      ),
    );
  }
}
