import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'member_avatar.dart';

class SharedGroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const SharedGroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final acceptedMembers = group.members.where((m) => m.isAccepted).toList();
    final pendingCount = group.members.where((m) => m.isPending).length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primaryLight.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
              ),
              child: Center(
                child: Text(group.emoji ?? '👥', style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 13),
            // Name + member count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${acceptedMembers.length} สมาชิก',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                        ),
                      ),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.amberLight,
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Text(
                            'รอ $pendingCount',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.amberText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Member avatar stack
            if (acceptedMembers.isNotEmpty)
              MemberAvatarStack(
                members: acceptedMembers
                    .asMap()
                    .entries
                    .map((e) => (
                          name: e.value.profile?.displayName ??
                              e.value.profile?.username ??
                              '?',
                          color: AppColors.memberColors[e.key % AppColors.memberColors.length],
                          avatarUrl: e.value.profile?.avatarUrl,
                        ))
                    .toList(),
                size: 24,
                maxVisible: 4,
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
