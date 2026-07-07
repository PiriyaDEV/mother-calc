import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'rounded_avatar.dart';

class FriendRow extends StatelessWidget {
  final Friend friend;
  final bool isDark;
  final VoidCallback onRemove;

  const FriendRow({
    super.key,
    required this.friend,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.read<LocaleProvider>();
    final myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final profile = friend.otherProfile(myId);
    final name = profile?.displayName ?? profile?.username ?? l.t('notifications_user_fallback');
    final username = profile?.username;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            RoundedAvatar(
              name: name,
              avatarUrl: profile?.avatarUrl,
              size: 40,
              radius: 16,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (username != null)
                    Text(
                      '@$username',
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
            // "เพื่อน ✓" badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 12, color: Color(0xFF16A34A)),
                  const SizedBox(width: 4),
                  Text(
                    l.t('friends_tab_label'),
                    style: GoogleFonts.notoSansThai(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 🗑️ Remove button
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.neutral600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
