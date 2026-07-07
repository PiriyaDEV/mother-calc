import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import 'profile_avatar.dart';
import 'toast_banner.dart';

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
    return Container(
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppGradients.primaryButtonDark
                  : AppGradients.primaryButtonLight,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppColors.shadowFloat,
            ),
            child: Row(
              children: [
                ProfileAvatar(
                  profile: profile,
                  size: 72,
                  uploading: uploading,
                  onPickAvatar: onPickAvatar,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ??
                            profile?.username ??
                            'ผู้ใช้',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (profile?.username != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@${profile!.username}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            color:
                                Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
